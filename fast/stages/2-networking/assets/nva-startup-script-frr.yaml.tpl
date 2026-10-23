#cloud-config

# NVA startup for the NCC router appliance mode: static per-NIC routes and
# optional masquerade as in the ILB sandwich template, plus a containerized FRR
# instance peering via eBGP with the Cloud Router interfaces of every VPC the
# NVA is attached to. The FRR configuration is rendered by the factory into the
# `nva-frr-config` metadata key and reloaded whenever it changes.

write_files:
  - path: /etc/frr/daemons
    permissions: "0644"
    content: |
      bgpd=yes
      zebra=yes
      vtysh_enable=yes
      zebra_options="  -A 127.0.0.1 -s 90000000"
      bgpd_options="   -A 127.0.0.1"
  - path: /etc/frr/vtysh.conf
    permissions: "0644"
    content: |
      service integrated-vtysh-config
  - path: /var/run/nva/frr-config-sync.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      # Fetch the FRR configuration from instance metadata, substitute the
      # router id with the primary NIC address and (re)start FRR when the
      # configuration changes. Runs forever in the background.
      METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance"
      METADATA_HEADER="Metadata-Flavor: Google"
      IP0=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/network-interfaces/0/ip")
      LAST_HASH=""
      while true; do
        CONFIG=$(curl -s -f -H "$${METADATA_HEADER}" "$${METADATA_URL}/attributes/nva-frr-config")
        if [ -n "$${CONFIG}" ]; then
          HASH=$(echo "$${CONFIG}" | md5sum | cut -d' ' -f1)
          if [ "$${HASH}" != "$${LAST_HASH}" ]; then
            echo "FRR configuration changed, applying."
            echo "$${CONFIG}" | sed "s/ROUTER_ID/$${IP0}/" > /etc/frr/frr.conf
            chown -R 100:101 /etc/frr || true
            # pull only when the image is not already cached locally; on first
            # boot the pull may race with Cloud NAT becoming available
            if ! docker image inspect ${frr_image} >/dev/null 2>&1; then
              for i in $(seq 1 30); do
                docker pull ${frr_image} && break
                echo "Image pull failed, retrying in 10s ($${i}/30)."
                sleep 10
              done
            fi
            docker rm -f frr 2>/dev/null || true
            docker run -d --name frr --restart=always --net=host \
              --cap-add=NET_ADMIN --cap-add=NET_RAW --cap-add=NET_BIND_SERVICE \
              --cap-add=SYS_ADMIN -v /etc/frr:/etc/frr ${frr_image} && \
              LAST_HASH="$${HASH}"
          fi
        fi
        sleep 30
      done

runcmd:
  - |
    #!/bin/bash
    set -ex

    echo "Starting NVA network configuration..."

    echo "Enabling IP forwarding and loose reverse path filtering."
    cat > /etc/sysctl.d/90-nva.conf <<EOF
    net.ipv4.ip_forward = 1
    net.ipv4.conf.all.rp_filter = 2
    net.ipv4.conf.default.rp_filter = 2
    EOF
    sysctl -p /etc/sysctl.d/90-nva.conf

    iptables -I FORWARD -j ACCEPT
    # let Cloud Router initiated BGP sessions in through the host firewall
    iptables -I INPUT -p tcp --dport 179 -j ACCEPT

    METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces"
    METADATA_HEADER="Metadata-Flavor: Google"
    INTERFACE_INDEXES=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/" | sed 's:/$::')

    for i in $${INTERFACE_INDEXES}; do
      IF_NAME="eth$${i}"
      echo "Configuring interface $${IF_NAME}..."

      GATEWAY=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${i}/gateway")
      if [ -z "$${GATEWAY}" ]; then
        echo "Could not retrieve gateway for $${IF_NAME}. Skipping."
        continue
      fi
      echo "Gateway for $${IF_NAME} is $${GATEWAY}."
      # loose rp_filter per interface (sysctl "all" is a max with per-if)
      sysctl -w net.ipv4.conf.$${IF_NAME}.rp_filter=2 || true

      %{ for nic_index, nic in nva_nics_config ~}
      %{ if can(nic.routes) || try(nic.masquerade, false) ~}
      if [ "$${i}" == "${nic_index}" ]; then
        %{ if can(nic.routes) ~}
        %{ for route in nic.routes ~}
        echo "Adding route for ${route} via $${GATEWAY} on $${IF_NAME}"
        ip route add ${route} via $${GATEWAY} dev $${IF_NAME} proto static
        %{ endfor ~}
        %{ endif ~}
        %{ if try(nic.masquerade, false) ~}
        echo "Enabling NAT (Masquerade) on $${IF_NAME} and setting default route."
        ip route replace default via $${GATEWAY} dev $${IF_NAME}
        %{ for range in try(nic.masquerade_exclude, []) ~}
        # keep source addresses for traffic that stays private, so that an
        # active/standby switch does not reset flows through the NAT
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -d ${range} -j RETURN
        %{ endfor ~}
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -j MASQUERADE
        %{ endif ~}
      fi
      %{ endif ~}
      %{ endfor ~}
    done

    echo "Starting FRR configuration sync."
    nohup /var/run/nva/frr-config-sync.sh >> /var/log/nva-frr-sync.log 2>&1 &

    echo "NVA network configuration complete."

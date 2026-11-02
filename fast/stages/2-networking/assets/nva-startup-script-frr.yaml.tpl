#cloud-config

# NVA startup configuration for NCC Router Appliance (BGP) mode (runs on
# Container-Optimized OS):
# 1. Enables IPv4 forwarding, sets loose reverse-path filtering (`rp_filter=2`),
#    and opens the COS host firewall (`iptables` defaults to DROP on INPUT and
#    FORWARD) for transit traffic, BGP (TCP 179), and GCP health check probers.
# 2. Programs per-NIC static kernel routes (`routes`) and optional outbound SNAT
#    (`masquerade` / `masquerade_exclude`) via each NIC's VPC subnet gateway.
# 3. Starts a per-NIC Policy-Based Routing (PBR) daemon (`update-pbrs.sh`) so
#    GCP health check probes arriving on secondary NICs (`eth1+`) or ILB VIPs
#    return out the ingress NIC rather than following `eth0`'s default route.
# 4. Starts a background daemon (`frr-config-sync.sh`) that polls the
#    `nva-frr-config` instance metadata key every 30s and runs FRR (`bgpd` +
#    `zebra`) in a container sharing the host network namespace.

write_files:
  # Enable `zebra` (kernel FIB manager) and `bgpd` inside the FRR container;
  # `-A 127.0.0.1` binds VTY sockets to loopback only and `-s 90000000` raises
  # Zebra's netlink socket buffer size.
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
  - path: /var/run/nva/update-pbrs.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      # Policy-Based Routing (PBR) daemon for a single network interface.
      #
      # Why this is needed: Linux shares a single `main` routing table across
      # all NICs where the default route points out `eth0`. When GCP health
      # check probers (`35.191.0.0/16`, `130.211.0.0/22`) probe a secondary NIC
      # (`eth1+`) or an Internal Passthrough NLB VIP (`forwarded-ips`), reply
      # packets would otherwise exit via `eth0` and be dropped by GCP's strict
      # VPC return-path anti-spoofing check.
      #
      # For interface `ethN`, this loop maintains routing table `110 + N` with a
      # default route via `ethN`'s subnet gateway (re-applied inside the loop so
      # it survives FRR/Zebra restarts) and syncs `ip rule` entries directing
      # replies from `ethN`'s primary IP and any ILB `forwarded-ips` back to
      # the health check ranges through table `110 + N`.
      set -e

      IF_INDEX=$1
      METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces"
      METADATA_HEADER="Metadata-Flavor: Google"
      IF_NAME="eth$${IF_INDEX}"
      TABLE_ID=$((110 + IF_INDEX))

      GATEWAY=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/gateway")
      NIC_IP=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/ip")
      if [ -z "$${GATEWAY}" ]; then
        echo "Could not retrieve gateway. Exiting."
        exit 1
      fi

      while true; do
        # Omit `proto static` so FRR's `staticd`/`zebra` does not purge the
        # route when the FRR container starts or restarts.
        ip route replace default via $${GATEWAY} dev $${IF_NAME} onlink table $${TABLE_ID} || true
        FORWARDED_IPS_LIST=()
        if [ -n "$${NIC_IP}" ]; then
          FORWARDED_IPS_LIST+=("$${NIC_IP}")
        fi
        FORWARDED_IP_IDS=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/forwarded-ips/")
        for ID in $${FORWARDED_IP_IDS}; do
          IP=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/forwarded-ips/$${ID}")
          FORWARDED_IPS_LIST+=("$${IP}")
        done
        FORWARDED_IPS=$(printf "%s\n" "$${FORWARDED_IPS_LIST[@]}")

        CURRENT_RULE_IPS=$(ip rule show | grep "lookup $${TABLE_ID}" | awk -F 'from ' '/from/ {split($2, a, " "); print a[1]}' | sort -u || true)

        for IP in $${FORWARDED_IPS}; do
          if ! echo "$${CURRENT_RULE_IPS}" | grep -q "^$${IP}$"; then
            ip rule add from $${IP} to 35.191.0.0/16 lookup $${TABLE_ID}
            ip rule add from $${IP} to 130.211.0.0/22 lookup $${TABLE_ID}
          fi
        done

        for IP in $${CURRENT_RULE_IPS}; do
          if ! echo "$${FORWARDED_IPS}" | grep -q "^$${IP}$"; then
            ip rule del from $${IP} to 35.191.0.0/16 lookup $${TABLE_ID} || true
            ip rule del from $${IP} to 130.211.0.0/22 lookup $${TABLE_ID} || true
          fi
        done

        sleep 5
      done
  - path: /var/run/nva/frr-config-sync.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      # Poll the `nva-frr-config` instance metadata attribute every 30s,
      # substitute `ROUTER_ID` with `eth0`'s primary IPv4 address, and (re)start
      # the FRR container whenever the rendered configuration hash changes.
      # Keeping the FRR config in a dedicated metadata key lets Terraform update
      # BGP peers, timers, and advertised prefixes in place without recreating
      # the NVA VM.
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
            # UID:GID 100:101 is the `frr:frr` user inside the FRR container
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
            # Run FRR in the host network namespace (`--net=host`) with netlink
            # capabilities so `bgpd` binds directly to `eth0..ethN` and `zebra`
            # programs dynamic BGP routes into the host Linux kernel FIB.
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

    # Enable IPv4 packet forwarding across NICs and set loose Reverse Path
    # Filtering (`rp_filter = 2`) so packets arriving on one NIC whose source
    # prefix is reachable via another routing table/NIC are not dropped as
    # martians.
    echo "Enabling IP forwarding and loose reverse path filtering."
    cat > /etc/sysctl.d/90-nva.conf <<EOF
    net.ipv4.ip_forward = 1
    net.ipv4.conf.all.rp_filter = 2
    net.ipv4.conf.default.rp_filter = 2
    EOF
    sysctl -p /etc/sysctl.d/90-nva.conf

    # Container-Optimized OS sets default `DROP` policies on `INPUT` and
    # `FORWARD`; explicitly allow transit forwarding, Cloud Router-initiated
    # BGP connections (TCP 179), and GCP health check probers.
    iptables -I FORWARD -j ACCEPT
    iptables -I INPUT -p tcp --dport 179 -j ACCEPT
    iptables -I INPUT -s 35.191.0.0/16,130.211.0.0/22 -j ACCEPT

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
      # Linux evaluates effective rp_filter as max(conf.all, conf.<if>), and
      # interfaces are initialized with rp_filter=1 before cloud-init runs.
      sysctl -w net.ipv4.conf.$${IF_NAME}.rp_filter=2 || true

      %{ for nic_index, nic in nva_nics_config ~}
      %{ if can(nic.routes) || try(nic.masquerade, false) ~}
      if [ "$${i}" == "${nic_index}" ]; then
        %{ if can(nic.routes) ~}
        %{ for route in nic.routes ~}
        # Static kernel route (`RTPROT_BOOT`, without `proto static` so FRR does
        # not delete it on startup) directing data-plane traffic for `${route}`
        # out this NIC via its VPC subnet gateway.
        echo "Adding route for ${route} via $${GATEWAY} on $${IF_NAME}"
        ip route replace ${route} via $${GATEWAY} dev $${IF_NAME}
        %{ endfor ~}
        %{ endif ~}
        %{ if try(nic.masquerade, false) ~}
        echo "Enabling NAT (Masquerade) on $${IF_NAME} and setting default route."
        ip route replace default via $${GATEWAY} dev $${IF_NAME}
        %{ for range in try(nic.masquerade_exclude, []) ~}
        # Exclude private destination ranges from SNAT so internal/on-premises
        # flows preserve their original client source IP and do not reset when
        # failing over between active and standby NVA instances.
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -d ${range} -j RETURN
        %{ endfor ~}
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -j MASQUERADE
        %{ endif ~}
      fi
      %{ endif ~}
      %{ endfor ~}

      # Invoke via `bash` because `/var/run` (`/run` tmpfs) is mounted `noexec` on COS.
      echo "Starting continuous PBR update for eth$${i} in the background."
      nohup bash /var/run/nva/update-pbrs.sh $i >> /var/log/nva-pbr-update.log 2>&1 &
    done

    echo "Starting FRR configuration sync."
    nohup bash /var/run/nva/frr-config-sync.sh >> /var/log/nva-frr-sync.log 2>&1 &

    echo "NVA network configuration complete."

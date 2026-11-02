#cloud-config

# NVA startup configuration for Internal Passthrough NLB (ILB sandwich) mode:
# 1. Enables IPv4 packet forwarding across all network interfaces.
# 2. Programs per-NIC static kernel routes (`routes`) and optional outbound SNAT
#    (`masquerade` / `masquerade_exclude`) via each NIC's VPC subnet gateway.
# 3. Runs a per-NIC Policy-Based Routing (PBR) daemon (`update-pbrs.sh`) so
#    health check probes sent to an ILB VIP (`forwarded-ips`) on `ethN` are
#    answered via `ethN`'s subnet gateway rather than `eth0`'s default route.

write_files:
  - path: /var/run/nva/update-pbrs.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      # Policy-Based Routing (PBR) daemon for an interface fronting an ILB.
      #
      # GCP Internal Passthrough NLBs deliver packets and health check probes
      # (`35.191.0.0/16`, `130.211.0.0/22`) to the backend VM with the ILB's VIP
      # as the destination IP (published in metadata under `forwarded-ips/`).
      # Because Linux uses a single `main` routing table whose default route
      # points out `eth0`, health check replies from `eth1+` would exit `eth0`
      # and be dropped by VPC anti-spoofing unless steered back out `ethN` via
      # a per-NIC routing table (`110 + IF_INDEX`).
      set -e

      IF_INDEX=$1
      METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces"
      METADATA_HEADER="Metadata-Flavor: Google"
      FORWARDED_IPS=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/forwarded-ips/")
      IF_NAME="eth$${IF_INDEX}"
      TABLE_ID=$((110 + IF_INDEX))

      echo "Starting."

      GATEWAY=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/gateway")
      if [ -z "$${GATEWAY}" ]; then
        echo "Could not retrieve gateway. Exiting."
        exit 1
      fi

      echo "Initial PBR configuration using table $${TABLE_ID}."
      ip route add default via $${GATEWAY} dev $${IF_NAME} proto static onlink table $${TABLE_ID} || true

      while true; do
        echo "Checking for PBR updates."

        FORWARDED_IPS_LIST=()
        FORWARDED_IP_IDS=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/forwarded-ips/")
        for ID in $${FORWARDED_IP_IDS}; do
          IP=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${IF_INDEX}/forwarded-ips/$${ID}")
          FORWARDED_IPS_LIST+=("$${IP}")
        done
        FORWARDED_IPS=$(printf "%s\n" "$${FORWARDED_IPS_LIST[@]}")

        CURRENT_RULE_IPS=$(ip rule show | grep "lookup $${TABLE_ID}" | awk -F 'from ' '/from/ {split($2, a, " "); print a[1]}' | sort -u || true)

        for IP in $${FORWARDED_IPS}; do
          if ! echo "$${CURRENT_RULE_IPS}" | grep -q "^$${IP}$"; then
            echo "Adding PBR rules for forwarded IP $${IP}."
            ip rule add from $${IP} to 35.191.0.0/16 lookup $${TABLE_ID}
            ip rule add from $${IP} to 130.211.0.0/22 lookup $${TABLE_ID}
          fi
        done

        for IP in $${CURRENT_RULE_IPS}; do
          if ! echo "$${FORWARDED_IPS}" | grep -q "^$${IP}$"; then
            echo "Removing PBR rules for forwarded IP $${IP}."
            ip rule del from $${IP} to 35.191.0.0/16 lookup $${TABLE_ID} || true
            ip rule del from $${IP} to 130.211.0.0/22 lookup $${TABLE_ID} || true
          fi
        done

        sleep 5
      done

runcmd:
  - |
    #!/bin/bash
    set -ex

    echo "Starting NVA network configuration..."

    echo "Enabling IP forwarding."
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/90-ip-forwarding.conf
    sysctl -p /etc/sysctl.d/90-ip-forwarding.conf

    iptables -I FORWARD -j ACCEPT

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

      %{ for nic_index, nic in nva_nics_config ~}
      %{ if can(nic.routes) || try(nic.masquerade, false) ~}
      if [ "$${i}" == "${nic_index}" ]; then
        %{ if can(nic.routes) ~}
        %{ for route in nic.routes ~}
        # Install static kernel route for `${route}` via this NIC's VPC subnet gateway.
        echo "Adding route for ${route} via $${GATEWAY} on $${IF_NAME}"
        ip route add ${route} via $${GATEWAY} dev $${IF_NAME} proto static
        %{ endfor ~}
        %{ endif ~}
        %{ if try(nic.masquerade, false) ~}
        echo "Enabling NAT (Masquerade) on $${IF_NAME} and setting default route."
        ip route replace default via $${GATEWAY} dev $${IF_NAME}
        %{ for range in try(nic.masquerade_exclude, []) ~}
        # Exclude private destination ranges from SNAT so internal flows keep
        # their original source IP across the appliance.
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -d ${range} -j RETURN
        %{ endfor ~}
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -j MASQUERADE
        %{ endif ~}
      fi
      %{ endif ~}
      %{ endfor ~}

      echo "Starting continuous PBR update for eth$${i} in the background."
      nohup /var/run/nva/update-pbrs.sh $i >> /var/log/nva-pbr-update.echo 2>&1 &
    done

    echo "NVA network configuration complete."

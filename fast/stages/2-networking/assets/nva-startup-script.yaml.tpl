#cloud-config

runcmd:
  - |
    #!/bin/bash
    set -ex

    echo "Starting NVA network configuration..."

    echo "Enabling IP forwarding."
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/90-ip-forwarding.conf
    sysctl -p /etc/sysctl.d/90-ip-forwarding.conf

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
      if [ "$${i}" == "${nic_index}" ]; then
        %{ for route in nic.routes ~}
        echo "Adding route for ${route} via $${GATEWAY} on $${IF_NAME}"
        ip route add ${route} via $${GATEWAY} dev $${IF_NAME} proto static
        %{ endfor ~}
        %{ if try(nic.masquerade, false) ~}
        echo "Enabling NAT (Masquerade) on $${IF_NAME}."
        iptables -t nat -A POSTROUTING -o $${IF_NAME} -j MASQUERADE
        %{ endif ~}
      fi
      %{ endfor ~}

      FORWARDED_IPS=$(curl -s -H "$${METADATA_HEADER}" "$${METADATA_URL}/$${i}/forwarded-ips/")
      if [ -n "$${FORWARDED_IPS}" ]; then
        TABLE_ID=$((110 + i))
        echo "Configuring PBR for health checks on $${IF_NAME} using table $${TABLE_ID}."

        ip route add default via $${GATEWAY} dev $${IF_NAME} proto static onlink table $${TABLE_ID}

        for FW_IP in $${FORWARDED_IPS}; do
          echo "Adding PBR rules for forwarded IP $${FW_IP}."
          ip rule add from $${FW_IP} to 35.191.0.0/16 lookup $${TABLE_ID}
          ip rule add from $${FW_IP} to 130.211.0.0/22 lookup $${TABLE_ID}
        done
      fi
    done

    echo "NVA network configuration complete."
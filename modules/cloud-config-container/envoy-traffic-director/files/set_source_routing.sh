#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -exuf -o pipefail

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.send_redirects=0

for IFACE in $(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/ | grep -v ^0\/$ | sed 's|/||');
  do
    GATEWAY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/${IFACE}/gateway)
    sysctl -w net.ipv4.conf.eth${IFACE}.rp_filter=2
    echo "${IFACE} rt${IFACE}" | sudo tee -a /etc/iproute2/rt_tables
    iptables -t mangle -A PREROUTING -i eth${IFACE} -m conntrack --ctstate NEW -j CONNMARK --set-mark ${IFACE}
    ip rule add fwmark ${IFACE} table rt${IFACE}
    ip route add default via ${GATEWAY} dev eth${IFACE} table rt${IFACE}
  done
iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
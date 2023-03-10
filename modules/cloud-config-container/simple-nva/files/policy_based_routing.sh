#!/bin/bash

# Copyright 2023 Google LLC
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

IF_NAME=$1
IF_NUMBER=$(echo $IF_NAME | sed -e s/eth//)
IF_GW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/gateway -H "Metadata-Flavor: Google")
IF_IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/ip -H "Metadata-Flavor: Google")
IF_NETMASK=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/subnetmask -H "Metadata-Flavor: Google")
IF_IP_PREFIX=$(/var/run/nva/ipprefix_by_netmask.sh $IF_NETMASK)

# Sleep while there's no load balancer IP route for this IF
while true
do
  IPS_LB_STR=$(ip r show table local | grep "$IF_NAME proto 66" | cut -f 2 -d " " |  tr -s '\n' ' ')
  IPS_LB=($IPS_LB_STR)
  for IP in "${IPS_LB[@]}"
  do
    # Configure hc routing table if not available for this network interface
    grep -qxF "$((200 + $IF_NUMBER)) hc-$IF_NAME" /etc/iproute2/rt_tables || {
      echo "$((200 + $IF_NUMBER)) hc-$IF_NAME" >>/etc/iproute2/rt_tables
      ip route add $IF_GW src $IF_IP dev $IF_NAME table hc-$IF_NAME
      ip route add default via $IF_GW dev $IF_NAME table hc-$IF_NAME
    }

    # configure PBR route for LB
    ip rule list | grep -qF "$IP" || ip rule add from $IP/32 table hc-$IF_NAME
  done

  # remove previously configure PBR for old LB removed from network interface
  # first get list of PBR on this network interface and retrieve LB IP addresses
  PBR_LB_IPS_STR=$(ip rule list | grep "hc-$IF_NAME" | cut -f 2 -d " " |  tr -s '\n' ' ')
  PBR_LB_IPS=($PBR_LB_IPS_STR)

  # iterate over PBR LB IP addresses
  for PBR_IP in "${PBR_LB_IPS[@]}"
  do
    # check if the PBR LB IP belongs to the current array of LB IPs attached to the
    # network interface, if not delete the corresponding PBR rule
    if [ -z "$IPS_LB" ] || ! echo ${IPS_LB[@]} | grep --quiet "$PBR_IP" ; then
      ip rule del from $PBR_IP
    fi
  done
  sleep 2
done

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

# Check whether there are LB for this network interface
# Curl to forwarded-ips endpoint return indexes zero based (e.g. 0 \n 1) for every LB associated to the IF, "" otherwise
IF_LB=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/forwarded-ips/ -H "Metadata-Flavor: Google" |  tr -s '\n' ' ')
IP_LB=$(ip r show table local | grep "$IF_NAME proto 66" | cut -f 2 -d " " |  tr -s '\n' ' ')

if [ ! -z "$IF_LB" ] ; then
  # Sleep while there's no load balancer IP route for this IF
  while [ -z "$IP_LB" ] ; do
    sleep 2
    IP_LB=$(ip r show table local | grep "$IF_NAME proto 66" | cut -f 2 -d " " |  tr -s '\n' ' ')
  done
fi

IF_GW=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/gateway -H "Metadata-Flavor: Google")
IF_IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/ip -H "Metadata-Flavor: Google")
IF_NETMASK=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/$IF_NUMBER/subnetmask -H "Metadata-Flavor: Google")
IF_IP_PREFIX=$(/var/run/nva/ipprefix_by_netmask.sh $IF_NETMASK)
grep -qxF "$((200 + $IF_NUMBER)) hc-$IF_NAME" /etc/iproute2/rt_tables || echo "$((200 + $IF_NUMBER)) hc-$IF_NAME" >>/etc/iproute2/rt_tables
ip route add $IF_GW src $IF_IP dev $IF_NAME table hc-$IF_NAME
ip route add default via $IF_GW dev $IF_NAME table hc-$IF_NAME

# Skip route configuration when no LB is associated to the network interface
if [ ! -z "$IF_LB" ] ; then
  # Convert whitespace separated list of IPs to array
  IPS_LB=($IP_LB)
  for IP in "${IPS_LB[@]}" 
  do
    ip rule add from $IP/32 table hc-$IF_NAME
  done
fi
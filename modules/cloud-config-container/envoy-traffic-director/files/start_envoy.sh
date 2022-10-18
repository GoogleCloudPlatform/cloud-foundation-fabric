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

ENVOY_NODE_ID=$(uuidgen)
ENVOY_ZONE=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/zone | cut -f 4 -d '/')
CONFIG_PROJECT_NUMBER=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/network | cut -f 2 -d '/')
VPC_NETWORK_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/network | cut -f 4 -d '/')
sed -i "s/ENVOY_NODE_ID/${ENVOY_NODE_ID}/" /etc/envoy/envoy.yaml
sed -i "s/ENVOY_ZONE/${ENVOY_ZONE}/" /etc/envoy/envoy.yaml
sed -i "s/CONFIG_PROJECT_NUMBER/${CONFIG_PROJECT_NUMBER}/" /etc/envoy/envoy.yaml
sed -i "s/VPC_NETWORK_NAME/${VPC_NETWORK_NAME}/" /etc/envoy/envoy.yaml

IP_ADDRESS=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

iptables -t nat -N ENVOY_IN_REDIRECT
# Do not redirect to Envoy SSH traffic to the instance primary (nic0) IP
iptables -t nat -A ENVOY_IN_REDIRECT -p tcp -d ${IP_ADDRESS}/32 --dport 22 -j RETURN
# Do not redirect to Envoy health checking traffic
iptables -t nat -A ENVOY_IN_REDIRECT -p tcp -s 130.211.0.0/22,35.191.0.0/16 --dport 15000 --j RETURN
# Redirect all else to Envoy
iptables -t nat -A ENVOY_IN_REDIRECT -p tcp -j REDIRECT --to-port 15001
iptables -t nat -A PREROUTING -p tcp -m tcp -j ENVOY_IN_REDIRECT
# Allow all traffic redirected to Envoy
iptables -t filter -A INPUT -p tcp -m tcp --dport 15001 -m state --state NEW,ESTABLISHED -j ACCEPT
# Allow traffic to the admin port only from the health checking ranges
iptables -t filter -A INPUT -p tcp -m tcp -s 130.211.0.0/22,35.191.0.0/16 --dport 15000 -m state --state NEW,ESTABLISHED -j ACCEPT
systemctl daemon-reload
systemctl start envoy
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

echo 'Enabling IP forwarding'
sed '/net.ipv4.ip_forward=1/s/^#//g' -i /etc/sysctl.conf &&
sysctl -p /etc/sysctl.conf &&
/etc/init.d/procps restart

echo 'Setting NAT masquerade (for Internet connectivity)'
iptables -t nat -A POSTROUTING -o eth0 -d 10.0.0.0/8 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -d 172.16.0.0/12 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -d 192.168.0.0/16 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#!/bin/bash

echo 'Enabling IP forwarding'
sed '/net.ipv4.ip_forward=1/s/^#//g' -i /etc/sysctl.conf &&
sysctl -p /etc/sysctl.conf &&
/etc/init.d/procps restart

echo 'Setting Routes'
ip route add 10.128.32.0/19 via 10.128.0.1 dev ens4
ip route add 10.128.96.0/19 via 10.128.64.1 dev ens5
ip route add 10.128.128.0/19 via 10.128.64.1 dev ens5
ip route add 10.128.160.0/19 via 10.128.64.1 dev ens5
ip route add 10.128.192.0/19 via 10.128.64.1 dev ens5
ip route add 10.128.224.0/19 via 10.128.64.1 dev ens5
# TODO: set this to the right on-prem range before merging
ip route add 10.0.0.0/24 via 10.128.64.1 dev ens5

echo 'Adding PBR rules to answer HCs also from the secondary nic'
grep -qxF '200 hc' /etc/iproute2/rt_tables || echo '200     hc' >> /etc/iproute2/rt_tables
ip_addr_ens5=$(ip route ls table local | awk '/ens5 proto 66 scope host/ {print $2}')
while [ -z $ip_addr_ens5 ]; do
  echo 'Waiting for networking stack to be ready'
  sleep 2
  ip_addr_ens5=$(ip route ls table local | awk '/ens5 proto 66 scope host/ {print $2}')
done
ip rule add from $ip_addr_ens5 lookup hc
ip route add default via 10.128.64.1 dev ens5 table hc

echo 'Setting NAT masquerade (for Internet connectivity)'
iptables --append FORWARD --in-interface ens5 -j ACCEPT
iptables --table nat --append POSTROUTING --out-interface ens4 -j MASQUERADE

echo 'Installing Nginx for HC tests'
apt-get update &&
apt-get install -y nginx &&
echo 'Running' > /var/www/html/index.html

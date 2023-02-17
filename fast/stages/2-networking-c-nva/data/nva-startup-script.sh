#!/bin/bash

echo 'Enabling IP forwarding'
sed '/net.ipv4.ip_forward=1/s/^#//g' -i /etc/sysctl.conf &&
sysctl -p /etc/sysctl.conf &&
/etc/init.d/procps restart

echo 'Setting NAT masquerade (for Internet connectivity)'
iptables -t nat -A POSTROUTING -o eth0 -d 10.0.0.0/8 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -d 172.16.0.0/12 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -d 192.168.0.0/16 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
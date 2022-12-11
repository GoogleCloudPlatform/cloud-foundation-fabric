#!/bin/bash

#
# /etc/ipsec-vti.sh
# https://developers.microad.co.jp/entry/2022/05/30/100000
#

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=($${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=($${PLUTO_MARK_IN//// })

case "$PLUTO_CONNECTION" in
%{~ for i, peer in peer_configs }
gcp-vpn-tunnel-${i})
  VTI_INTERFACE=vti0${i+1}
  VTI_LOCALADDR=${peer.bgp_session.local_address}/30
  VTI_REMOTEADDR=${peer.bgp_session.peer_address}/30
  ;;
%{ endfor }
esac

# output parameters to /var/log/messages for debug
logger "ipsec-vti.sh: ================================================="
logger "ipsec-vti.sh: PLUTO_CONNECTION = $${PLUTO_CONNECTION}"
logger "ipsec-vti.sh: PLUTO_VERB = $${PLUTO_VERB}"
logger "ipsec-vti.sh: VTI_INTERFACE = $${VTI_INTERFACE}"
logger "ipsec-vti.sh: PLUTO_ME = $${PLUTO_ME}"
logger "ipsec-vti.sh: PLUTO_PEER = $${PLUTO_PEER}"
logger "ipsec-vti.sh: PLUTO_MARK_IN_ARR[0] = $${PLUTO_MARK_IN_ARR[0]}"
logger "ipsec-vti.sh: PLUTO_MARK_OUT_ARR[0] = $${PLUTO_MARK_OUT_ARR[0]}"
logger "ipsec-vti.sh: PLUTO_MARK_IN = $${PLUTO_MARK_IN}"
logger "ipsec-vti.sh: ================================================="

case "$${PLUTO_VERB}" in
up-client)
  $IP link add $${VTI_INTERFACE} type vti \
    local $${PLUTO_ME} remote $${PLUTO_PEER} \
    okey $${PLUTO_MARK_OUT_ARR[0]} ikey $${PLUTO_MARK_IN_ARR[0]}
  sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.disable_policy=1
  sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=2 || \
    sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=0
  $IP addr add $${VTI_LOCALADDR} remote $${VTI_REMOTEADDR} dev $${VTI_INTERFACE}
  $IP link set $${VTI_INTERFACE} up mtu 1436
  $IPTABLES -t mangle -I FORWARD -o $${VTI_INTERFACE} \
    -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  $IPTABLES -t mangle -I INPUT -p esp -s $${PLUTO_PEER} -d $${PLUTO_ME} \
    -j MARK --set-xmark $${PLUTO_MARK_IN}
  $IP route flush table 220
  ;;
down-client)
  $IP link del $${VTI_INTERFACE}
  $IPTABLES -t mangle -D FORWARD -o $${VTI_INTERFACE} \
    -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  $IPTABLES -t mangle -D INPUT -p esp -s $${PLUTO_PEER} -d $${PLUTO_ME} \
    -j MARK --set-xmark $${PLUTO_MARK_IN}
  ;;
esac

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.eth0.disable_xfrm=1
sysctl -w net.ipv4.conf.eth0.disable_policy=1

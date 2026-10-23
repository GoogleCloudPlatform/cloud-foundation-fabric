frr defaults traditional
hostname ${hostname}
log stdout informational
ip forwarding
!
%{~ for nic_index, nic in nva_nics_config }
%{~ if can(nic.bgp_inbound_deny) }
%{~ for prefix_index, prefix in nic.bgp_inbound_deny }
ip prefix-list PL-NIC${nic_index}-DENY seq ${5 + prefix_index * 5} permit ${prefix}
%{~ endfor }
%{~ endif }
! routes learned on this NIC are tagged so that they are not sent back to it
bgp community-list standard CL-NIC${nic_index}-LEARNED seq 5 permit ${bgp.asn}:${100 + nic_index}
%{~ endfor }
!
%{~ for nic_index, nic in nva_nics_config }
%{~ if can(nic.bgp_inbound_deny) }
route-map RM-NIC${nic_index}-IN deny 10
 match ip address prefix-list PL-NIC${nic_index}-DENY
!
%{~ endif }
route-map RM-NIC${nic_index}-IN permit 20
 set community ${bgp.asn}:${100 + nic_index} additive
!
route-map RM-NIC${nic_index}-OUT deny 20
 match community CL-NIC${nic_index}-LEARNED
!
route-map RM-NIC${nic_index}-OUT permit 100
!
%{~ endfor }
router bgp ${bgp.asn}
 bgp router-id ROUTER_ID
 bgp log-neighbor-changes
 no bgp ebgp-requires-policy
 no bgp network import-check
 bgp bestpath as-path multipath-relax
 timers bgp ${bgp.keepalive} ${bgp.holdtime}
 ! GCE assigns /32 addresses, so Cloud Router interfaces are reached via the
 ! subnet gateway and fail FRR's eBGP connected check
%{~ for n in bgp.neighbors }
 neighbor ${n.ip} remote-as ${n.asn}
 neighbor ${n.ip} description ${n.router}
 neighbor ${n.ip} update-source eth${n.nic_index}
 neighbor ${n.ip} disable-connected-check
%{~ if n.password != null }
 neighbor ${n.ip} password ${n.password}
%{~ endif }
%{~ endfor }
 !
 address-family ipv4 unicast
%{~ for nic_index, nic in nva_nics_config }
%{~ if can(nic.advertise) }
%{~ for prefix in nic.advertise }
  ! originated toward every neighbor; the kernel route comes from the NIC
  ! `routes` (static via the subnet gateway), not from BGP
  network ${prefix}
%{~ endfor }
%{~ endif }
%{~ endfor }
%{~ for n in bgp.neighbors }
  neighbor ${n.ip} soft-reconfiguration inbound
  ! MED neutral: FRR strips the MED toward eBGP peers by default, pass the
  ! Cloud Router value through instead; priorities are set by Cloud Router
  ! import policies
  neighbor ${n.ip} attribute-unchanged med
  neighbor ${n.ip} route-map RM-NIC${n.nic_index}-IN in
  neighbor ${n.ip} route-map RM-NIC${n.nic_index}-OUT out
%{~ endfor }
 exit-address-family
!
line vty
!

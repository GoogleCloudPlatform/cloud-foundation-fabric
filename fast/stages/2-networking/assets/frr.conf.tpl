! FRR configuration for NCC Router Appliance NVAs.
!
! A single FRR instance in the default VRF peers via eBGP with the Cloud Router
! interfaces of every VPC the NVA is attached to. Routes learned on one NIC are
! tagged with a per-NIC BGP community so they are not re-advertised back to
! peers on the same NIC (split-horizon across redundant Cloud Router interfaces),
! and passed through unchanged to all other NICs (`attribute-unchanged med`).
! All path selection (active/standby, ECMP, and regional affinity) is controlled
! by Cloud Router import policies rather than on the appliance.
frr defaults traditional
hostname ${hostname}
log stdout informational
ip forwarding
!
! Per-NIC inbound prefix filters (`bgp_inbound_deny`) and split-horizon
! community lists (`<asn>:<100 + nic_index>`).
%{~ for nic_index, nic in nva_nics_config }
%{~ if can(nic.bgp_inbound_deny) }
%{~ for prefix_index, prefix in nic.bgp_inbound_deny }
ip prefix-list PL-NIC${nic_index}-DENY seq ${5 + prefix_index * 5} permit ${prefix}
%{~ endfor }
%{~ endif }
bgp community-list standard CL-NIC${nic_index}-LEARNED seq 5 permit ${bgp.asn}:${100 + nic_index}
%{~ endfor }
!
! Per-NIC route maps:
! - RM-NIC<n>-IN drops any prefix in `bgp_inbound_deny` (e.g. `0.0.0.0/0` from
!   a transit Cloud Router) and tags accepted routes with the NIC's community.
! - RM-NIC<n>-OUT drops routes carrying that NIC's community so routes learned
!   from one Cloud Router interface on `eth<n>` are never reflected back to the
!   redundant Cloud Router interface (or another router) on the same NIC.
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
 ! ROUTER_ID is substituted with eth0's primary IP by `frr-config-sync.sh`
 bgp router-id ROUTER_ID
 bgp log-neighbor-changes
 ! allow eBGP route exchange without requiring explicit route-maps on every AFI
 no bgp ebgp-requires-policy
 ! originate `network` statements (`advertise`) without requiring an exact-match
 ! route in the kernel/zebra RIB (allows static supernet `routes` to cover more
 ! specific `/24` BGP advertisements)
 no bgp network import-check
 bgp bestpath as-path multipath-relax
 timers bgp ${bgp.keepalive} ${bgp.holdtime}
 ! GCE assigns /32 addresses via DHCP, so Cloud Router interfaces in the same
 ! subnet are reached via the subnet gateway and fail FRR's eBGP connected
 ! check unless `disable-connected-check` is set; `update-source` binds each
 ! session to the guest NIC attached to that router's VPC
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
  ! Prefixes in `advertise` are originated toward every BGP neighbor (`network`
  ! statement). Because FRR assigns locally originated `network` routes weight
  ! 32768 (beating any eBGP route with weight 0), FRR never installs a BGP route
  ! in the Linux kernel for these prefixes; data-plane forwarding relies on the
  ! static kernel routes configured under `routes` (or `masquerade`) on the NIC.
%{~ for nic_index, nic in nva_nics_config }
%{~ if can(nic.advertise) }
%{~ for prefix in nic.advertise }
  network ${prefix}
%{~ endfor }
%{~ endif }
%{~ endfor }
  ! MED-neutral forwarding: FRR strips the received MED toward eBGP peers by
  ! default; `attribute-unchanged med` preserves the Cloud Router metric across
  ! the appliance while Cloud Router import policies control path priorities.
%{~ for n in bgp.neighbors }
  neighbor ${n.ip} soft-reconfiguration inbound
  neighbor ${n.ip} attribute-unchanged med
  neighbor ${n.ip} route-map RM-NIC${n.nic_index}-IN in
  neighbor ${n.ip} route-map RM-NIC${n.nic_index}-OUT out
%{~ endfor }
 exit-address-family
!
line vty
!

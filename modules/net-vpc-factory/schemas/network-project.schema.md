# Network Project Configuration (Single)

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **project_config**: *reference([projectConfig](#refs-projectConfig))*
- **ncc_hub_config**: *reference([nccHubConfig](#refs-nccHubConfig))*
- **vpc_config**: *reference([vpcConfigMap](#refs-vpcConfigMap))*

## Definitions

- **projectConfig**<a name="refs-projectConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**name**: *string*
    <br>*pattern: None*
  - **prefix**: *string*
    <br>*pattern: None*
  - **parent**: *string*
    <br>*pattern: None*
  - **project_reuse**: *object*
    <br>*additional properties: false*
    - **use_data_source**: *boolean*
    - **project_attributes**: *object*
      - ⁺**name**: *string*
        <br>*pattern: None*
      - ⁺**number**: *number*
      - **services_enabled**: *array*
        - items: *string*
          <br>*pattern: None*
  - **billing_account**: *string*
    <br>*pattern: None*
  - **deletion_policy**: *string*
    <br>*enum: ['DELETE', 'ABANDON']*, *pattern: None*
  - **default_service_account**: *string*
    <br>*enum: ['deprovision', 'disable', 'keep']*, *pattern: None*
  - **auto_create_network**: *boolean*
  - **project_create**: *boolean*
  - **shared_vpc_host_config**: *object*
    <br>*additional properties: false*
    - ⁺**enabled**: *boolean*
    - **service_projects**: *array*
      - items: *string*
        <br>*pattern: None*
  - **services**: *array*
    - items: *string*
      <br>*pattern: ^[a-z-]+\.googleapis\.com$*
  - **org_policies**: *reference([orgPolicies](#refs-orgPolicies))*
  - **metric_scopes**: *array*
    - items: *string*
      <br>*pattern: None*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iamBindings](#refs-iamBindings))*
  - **iam_bindings_additive**: *reference([iamBindingsAdditive](#refs-iamBindingsAdditive))*
  - **iam_by_principals**: *reference([iamByPrincipals](#refs-iamByPrincipals))*
  - **iam_by_principals_additive**: *reference([iamByPrincipals](#refs-iamByPrincipals))*
- **nccHubConfig**<a name="refs-nccHubConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**name**: *string*
    <br>*pattern: None*
  - **description**: *string*
    <br>*pattern: None*
  - **preset_topology**: *string*
    <br>*enum: ['MESH', 'STAR', 'PLANETARY']*, *pattern: None*
  - **export_psc**: *boolean*
  - **groups**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9_-]+$`**: *reference([nccGroup](#refs-nccGroup))*
- **nccGroup**<a name="refs-nccGroup"></a>: *object*
  <br>*additional properties: false*
  - **labels**: *reference([stringMap](#refs-stringMap))*
  - **description**: *string*
    <br>*pattern: None*
  - **auto_accept**: *array*
    - items: *string*
      <br>*pattern: None*
- **vpcConfigMap**<a name="refs-vpcConfigMap"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *reference([vpcConfigEntry](#refs-vpcConfigEntry))*
- **vpcConfigEntry**<a name="refs-vpcConfigEntry"></a>: *object*
  <br>*additional properties: false*
  - **auto_create_subnetworks**: *boolean*
  - **create_googleapis_routes**: *object*
    <br>*additional properties: false*
    - **private**: *boolean*
    - **private-6**: *boolean*
    - **restricted**: *boolean*
    - **restricted-6**: *boolean*
  - **delete_default_routes_on_create**: *boolean*
  - **description**: *string*
    <br>*pattern: None*
  - **dns_policy**: *object*
    <br>*additional properties: false*
    - **inbound**: *boolean*
    - **logging**: *boolean*
    - **outbound**: *object*
      <br>*additional properties: false*
      - **private_ns**: *array*
        - items: *string*
          <br>*pattern: None*
      - **public_ns**: *array*
        - items: *string*
          <br>*pattern: None*
  - **dns_zones**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([dnsZone](#refs-dnsZone))*
  - **firewall_policy_enforcement_order**: *string*
    <br>*enum: ['AFTER_CLASSIC_FIREWALL', 'BEFORE_CLASSIC_FIREWALL']*, *pattern: None*
  - **ipv6_config**: *object*
    <br>*additional properties: false*
    - **enable_ula_internal**: *boolean*
    - **internal_range**: *string*
      <br>*pattern: None*
  - **mtu**: *number*
  - **nat_config**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([natConfig](#refs-natConfig))*
  - **network_attachments**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([networkAttachment](#refs-networkAttachment))*
  - **policy_based_routes**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([policyBasedRoute](#refs-policyBasedRoute))*
  - **psa_config**: *array*
    - items: *reference([psaConfig](#refs-psaConfig))*
  - **routers**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([routerConfig](#refs-routerConfig))*
  - **routes**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([routeConfig](#refs-routeConfig))*
  - **routing_mode**: *string*
    <br>*enum: ['GLOBAL', 'REGIONAL']*, *pattern: None*
  - **subnets_factory_config**: *object*
    <br>*additional properties: false*
    - **context**: *object*
      <br>*additional properties: false*
      - **regions**: *reference([stringMap](#refs-stringMap))*
    - **subnets_folder**: *string*
      <br>*pattern: None*
  - **firewall_factory_config**: *object*
    <br>*additional properties: false*
    - **cidr_tpl_file**: *string*
      <br>*pattern: None*
    - **rules_folder**: *string*
      <br>*pattern: None*
  - **vpn_config**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([vpnConfig](#refs-vpnConfig))*
  - **peering_config**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([peeringConfig](#refs-peeringConfig))*
  - **ncc_config**: *reference([vpcNccConfig](#refs-vpcNccConfig))*
- **dnsZone**<a name="refs-dnsZone"></a>: *object*
  <br>*additional properties: false*
  - **force_destroy**: *boolean*
  - **description**: *string*
    <br>*pattern: None*
  - **iam**: *reference([iam](#refs-iam))*
  - **zone_config**: *reference([dnsZoneConfig](#refs-dnsZoneConfig))*
  - **recordsets**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9_. -]+$`**: *reference([dnsRecordSet](#refs-dnsRecordSet))*
- **dnsZoneConfig**<a name="refs-dnsZoneConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**domain**: *string*
    <br>*pattern: None*
  - **forwarding**: *object*
    <br>*additional properties: false*
    - **forwarders**: *reference([stringMap](#refs-stringMap))*
    - **client_networks**: *array*
      - items: *string*
        <br>*pattern: None*
  - **peering**: *object*
    <br>*additional properties: false*
    - **client_networks**: *array*
      - items: *string*
        <br>*pattern: None*
    - ⁺**peer_network**: *string*
      <br>*pattern: None*
  - **public**: *object*
    <br>*additional properties: false*
    - **dnssec_config**: *reference([dnssecConfig](#refs-dnssecConfig))*
    - **enable_logging**: *boolean*
  - **private**: *object*
    <br>*additional properties: false*
    - **client_networks**: *array*
      - items: *string*
        <br>*pattern: None*
    - **service_directory_namespace**: *string*
      <br>*pattern: None*
- **dnssecConfig**<a name="refs-dnssecConfig"></a>: *object*
  <br>*additional properties: false*
  - **non_existence**: *string*
    <br>*enum: ['nsec', 'nsec3']*, *pattern: None*
  - ⁺**state**: *string*
    <br>*enum: ['on', 'off', 'transfer']*, *pattern: None*
  - **key_signing_key**: *reference([dnsKeySpec](#refs-dnsKeySpec))*
  - **zone_signing_key**: *reference([dnsKeySpec](#refs-dnsKeySpec))*
- **dnsKeySpec**<a name="refs-dnsKeySpec"></a>: *object*
  <br>*additional properties: false*
  - ⁺**algorithm**: *string*
    <br>*enum: ['rsasha1', 'rsasha256', 'rsasha512', 'ecdsap256sha256', 'ecdsap384sha384']*, *pattern: None*
  - ⁺**key_length**: *number*
- **dnsRecordSet**<a name="refs-dnsRecordSet"></a>: *object*
  <br>*additional properties: false*
  - **ttl**: *number*
  - **records**: *array*
    - items: *string*
      <br>*pattern: None*
  - **geo_routing**: *array*
    - items: *reference([dnsGeoRoutingRule](#refs-dnsGeoRoutingRule))*
  - **wrr_routing**: *array*
    - items: *reference([dnsWrrRoutingRule](#refs-dnsWrrRoutingRule))*
- **dnsGeoRoutingRule**<a name="refs-dnsGeoRoutingRule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**location**: *string*
    <br>*pattern: None*
  - **records**: *array*
    - items: *string*
      <br>*pattern: None*
  - **health_checked_targets**: *array*
    - items: *reference([dnsHealthCheckedTarget](#refs-dnsHealthCheckedTarget))*
- **dnsHealthCheckedTarget**<a name="refs-dnsHealthCheckedTarget"></a>: *object*
  <br>*additional properties: false*
  - ⁺**load_balancer_type**: *string*
    <br>*pattern: None*
  - ⁺**ip_address**: *string*
    <br>*pattern: None*
  - ⁺**port**: *string*
    <br>*pattern: None*
  - ⁺**ip_protocol**: *string*
    <br>*pattern: None*
  - ⁺**network_url**: *string*
    <br>*pattern: None*
  - ⁺**project**: *string*
    <br>*pattern: None*
  - **region**: *string*
    <br>*pattern: None*
- **dnsWrrRoutingRule**<a name="refs-dnsWrrRoutingRule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**weight**: *number*
  - ⁺**records**: *array*
    - items: *string*
      <br>*pattern: None*
- **natConfig**<a name="refs-natConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**region**: *string*
    <br>*pattern: None*
  - **router_create**: *boolean*
  - **router_name**: *string*
    <br>*pattern: None*
  - **router_network**: *string*
    <br>*pattern: None*
  - **router_asn**: *number*
  - **type**: *string*
    <br>*enum: ['PUBLIC', 'PRIVATE']*, *pattern: None*
  - **addresses**: *array*
    - items: *string*
      <br>*pattern: None*
  - **endpoint_types**: *array*
    - items: *string*
      <br>*enum: ['ENDPOINT_TYPE_VM', 'ENDPOINT_TYPE_SWG', 'ENDPOINT_TYPE_MANAGED_PROXY_LB']*, *pattern: None*
  - **logging_filter**: *string*
    <br>*enum: ['ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL']*, *pattern: None*
  - **config_port_allocation**: *object*
    <br>*additional properties: false*
    - **enable_endpoint_independent_mapping**: *boolean*
    - **enable_dynamic_port_allocation**: *boolean*
    - **min_ports_per_vm**: *number*
    - **max_ports_per_vm**: *number*
  - **config_source_subnetworks**: *object*
    <br>*additional properties: false*
    - **all**: *boolean*
    - **primary_ranges_only**: *boolean*
    - **subnetworks**: *array*
      - items: *reference([natSourceSubnetwork](#refs-natSourceSubnetwork))*
  - **config_timeouts**: *object*
    <br>*additional properties: false*
    - **icmp**: *number*
    - **tcp_established**: *number*
    - **tcp_time_wait**: *number*
    - **tcp_transitory**: *number*
    - **udp**: *number*
  - **rules**: *array*
    - items: *reference([natRule](#refs-natRule))*
- **natSourceSubnetwork**<a name="refs-natSourceSubnetwork"></a>: *object*
  <br>*additional properties: false*
  - ⁺**self_link**: *string*
    <br>*pattern: None*
  - **all_ranges**: *boolean*
  - **primary_range**: *boolean*
  - **secondary_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
- **natRule**<a name="refs-natRule"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
    <br>*pattern: None*
  - ⁺**match**: *string*
    <br>*pattern: None*
  - **source_ips**: *array*
    - items: *string*
      <br>*pattern: None*
  - **source_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
- **networkAttachment**<a name="refs-networkAttachment"></a>: *object*
  <br>*additional properties: false*
  - ⁺**subnet**: *string*
    <br>*pattern: None*
  - **automatic_connection**: *boolean*
  - **description**: *string*
    <br>*pattern: None*
  - **producer_accept_lists**: *array*
    - items: *string*
      <br>*pattern: None*
  - **producer_reject_lists**: *array*
    - items: *string*
      <br>*pattern: None*
- **policyBasedRoute**<a name="refs-policyBasedRoute"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
    <br>*pattern: None*
  - **labels**: *reference([stringMap](#refs-stringMap))*
  - **priority**: *number*
  - **next_hop_ilb_ip**: *string*
    <br>*pattern: None*
  - **use_default_routing**: *boolean*
  - **filter**: *object*
    <br>*additional properties: false*
    - **ip_protocol**: *string*
      <br>*pattern: None*
    - **dest_range**: *string*
      <br>*pattern: None*
    - **src_range**: *string*
      <br>*pattern: None*
  - **target**: *object*
    <br>*additional properties: false*
    - **interconnect_attachment**: *string*
      <br>*pattern: None*
    - **tags**: *array*
      - items: *string*
        <br>*pattern: None*
- **psaConfig**<a name="refs-psaConfig"></a>: *object*
  <br>*additional properties: false*
  - **deletion_policy**: *string*
    <br>*enum: ['delete', 'abandon']*, *pattern: None*
  - **ranges**: *reference([stringMap](#refs-stringMap))*
  - **export_routes**: *boolean*
  - **import_routes**: *boolean*
  - **peered_domains**: *array*
    - items: *string*
      <br>*pattern: None*
  - **range_prefix**: *string*
    <br>*pattern: None*
  - **service_producer**: *string*
    <br>*pattern: None*
- **routerConfig**<a name="refs-routerConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**region**: *string*
    <br>*pattern: None*
  - **asn**: *number*
  - **custom_advertise**: *reference([customAdvertiseConfig](#refs-customAdvertiseConfig))*
  - **keepalive**: *number*
  - **name**: *string*
    <br>*pattern: None*
- **routeConfig**<a name="refs-routeConfig"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
    <br>*pattern: None*
  - ⁺**dest_range**: *string*
    <br>*pattern: None*
  - ⁺**next_hop_type**: *string*
    <br>*pattern: None*
  - ⁺**next_hop**: *string*
    <br>*pattern: None*
  - **priority**: *number*
  - **tags**: *array*
    - items: *string*
      <br>*pattern: None*
- **vpnConfig**<a name="refs-vpnConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**region**: *string*
    <br>*pattern: None*
  - **ncc_spoke_config**: *object*
    <br>*additional properties: false*
    - **hub**: *string*
      <br>*pattern: None*
    - **description**: *string*
      <br>*pattern: None*
    - **labels**: *reference([stringMap](#refs-stringMap))*
  - ⁺**peer_gateways**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([peerGateway](#refs-peerGateway))*
  - **router_config**: *reference([vpnRouterConfig](#refs-vpnRouterConfig))*
  - **stack_type**: *string*
    <br>*enum: ['IPV4_ONLY', 'IPV4_IPV6']*, *pattern: None*
  - ⁺**tunnels**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9-]+$`**: *reference([vpnTunnel](#refs-vpnTunnel))*
- **peerGateway**<a name="refs-peerGateway"></a>: *object*
  <br>*additional properties: false*
  - **external**: *reference([externalPeerGateway](#refs-externalPeerGateway))*
  - **gcp**: *string*
    <br>*pattern: None*
- **externalPeerGateway**<a name="refs-externalPeerGateway"></a>: *object*
  <br>*additional properties: false*
  - ⁺**redundancy_type**: *string*
    <br>*enum: ['SINGLE_IP_INTERNALLY_REDUNDANT', 'TWO_IPS_REDUNDANCY', 'FOUR_IPS_REDUNDANCY']*, *pattern: None*
  - ⁺**interfaces**: *array*
    - items: *string*
      <br>*pattern: None*
  - **description**: *string*
    <br>*pattern: None*
  - **name**: *string*
    <br>*pattern: None*
- **vpnRouterConfig**<a name="refs-vpnRouterConfig"></a>: *object*
  <br>*additional properties: false*
  - **asn**: *number*
  - **create**: *boolean*
  - **custom_advertise**: *reference([customAdvertiseConfig](#refs-customAdvertiseConfig))*
  - **keepalive**: *number*
  - **name**: *string*
    <br>*pattern: None*
  - **override_name**: *string*
    <br>*pattern: None*
- **vpnTunnel**<a name="refs-vpnTunnel"></a>: *object*
  <br>*additional properties: false*
  - **bgp_peer**: *reference([bgpPeerConfig](#refs-bgpPeerConfig))*
  - ⁺**bgp_session_range**: *string*
    <br>*pattern: None*
  - **ike_version**: *number*
    <br>*enum: [1, 2]*
  - **name**: *string*
    <br>*pattern: None*
  - **peer_external_gateway_interface**: *number*
  - **peer_router_interface_name**: *string*
    <br>*pattern: None*
  - **peer_gateway**: *string*
    <br>*pattern: None*
  - **router**: *string*
    <br>*pattern: None*
  - **shared_secret**: *string*
    <br>*pattern: None*
  - ⁺**vpn_gateway_interface**: *number*
- **bgpPeerConfig**<a name="refs-bgpPeerConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**address**: *string*
    <br>*pattern: None*
  - ⁺**asn**: *number*
  - **route_priority**: *number*
  - **custom_advertise**: *reference([customAdvertiseConfig](#refs-customAdvertiseConfig))*
  - **md5_authentication_key**: *object*
    <br>*additional properties: false*
    - ⁺**name**: *string*
      <br>*pattern: None*
    - **key**: *string*
      <br>*pattern: None*
  - **ipv6**: *object*
    <br>*additional properties: false*
    - **nexthop_address**: *string*
      <br>*pattern: None*
    - **peer_nexthop_address**: *string*
      <br>*pattern: None*
  - **name**: *string*
    <br>*pattern: None*
- **customAdvertiseConfig**<a name="refs-customAdvertiseConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**all_subnets**: *boolean*
  - **ip_ranges**: *reference([stringMap](#refs-stringMap))*
- **peeringConfig**<a name="refs-peeringConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**peer_network**: *string*
    <br>*pattern: None*
  - **routes_config**: *object*
    <br>*additional properties: false*
    - **export**: *boolean*
    - **import**: *boolean*
    - **public_export**: *boolean*
    - **public_import**: *boolean*
  - **stack_type**: *string*
    <br>*enum: ['IPV4_ONLY', 'IPV4_IPV6']*, *pattern: None*
- **vpcNccConfig**<a name="refs-vpcNccConfig"></a>: *object*
  <br>*additional properties: false*
  - ⁺**hub**: *string*
    <br>*pattern: None*
  - **description**: *string*
    <br>*pattern: None*
  - **labels**: *reference([stringMap](#refs-stringMap))*
  - **group**: *string*
    <br>*pattern: None*
  - **exclude_export_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
  - **include_export_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
- **stringMap**<a name="refs-stringMap"></a>: *object*
  *additional properties: String*
- **condition**<a name="refs-condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**expression**: *string*
    <br>*pattern: None*
  - ⁺**title**: *string*
    <br>*pattern: None*
  - **description**: *string*
    <br>*pattern: None*
- **principalPattern**<a name="refs-principalPattern"></a>: *string*
  <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **rolePattern**<a name="refs-rolePattern"></a>: *string*
  <br>*pattern: ^roles/*
- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
    - items: *reference([principalPattern](#refs-principalPattern))*
- **iamBindings**<a name="refs-iamBindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**members**: *array*
      - items: *reference([principalPattern](#refs-principalPattern))*
    - **role**: *reference([rolePattern](#refs-rolePattern))*
    - **condition**: *reference([condition](#refs-condition))*
- **iamBindingsAdditive**<a name="refs-iamBindingsAdditive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *reference([principalPattern](#refs-principalPattern))*
    - **role**: *reference([rolePattern](#refs-rolePattern))*
    - **condition**: *reference([condition](#refs-condition))*
- **iamByPrincipals**<a name="refs-iamByPrincipals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])`**: *array*
    - items: *reference([rolePattern](#refs-rolePattern))*
- **orgPolicies**<a name="refs-orgPolicies"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+\.`**: *reference([orgPolicyConfig](#refs-orgPolicyConfig))*
- **orgPolicyConfig**<a name="refs-orgPolicyConfig"></a>: *object*
  - **inherit_from_parent**: *boolean*
  - **reset**: *boolean*
  - **rules**: *array*
    - items: *reference([orgPolicyRule](#refs-orgPolicyRule))*
- **orgPolicyRule**<a name="refs-orgPolicyRule"></a>: *object*
  <br>*additional properties: false*
  - **allow**: *reference([orgPolicyRuleAllowDeny](#refs-orgPolicyRuleAllowDeny))*
  - **deny**: *reference([orgPolicyRuleAllowDeny](#refs-orgPolicyRuleAllowDeny))*
  - **enforce**: *boolean*
  - **condition**: *object*
    <br>*additional properties: false*
    - **description**: *string*
      <br>*pattern: None*
    - **expression**: *string*
      <br>*pattern: None*
    - **location**: *string*
      <br>*pattern: None*
    - **title**: *string*
      <br>*pattern: None*
- **orgPolicyRuleAllowDeny**<a name="refs-orgPolicyRuleAllowDeny"></a>: *object*
  <br>*additional properties: false*
  - **all**: *boolean*
  - **values**: *array*
    - items: *string*
      <br>*pattern: None*

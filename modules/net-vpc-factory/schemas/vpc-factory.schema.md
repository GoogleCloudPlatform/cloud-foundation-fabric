# VPC Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**project_id**: *string*
- ⁺**name**: *string*
- **description**: *string*
- **auto_create_subnetworks**: *boolean*
- **bgp_config**: *reference([bgp_config](#refs-bgp_config))*
- **delete_default_routes_on_create**: *boolean*
- **mtu**: *number*
- **routing_mode**: *string*
  <br>*enum: ['GLOBAL', 'REGIONAL']*
- **firewall_policy_enforcement_order**: *string*
  <br>*enum: ['BEFORE_CLASSIC_FIREWALL', 'AFTER_CLASSIC_FIREWALL']*
- **create_googleapis_routes**: *reference([create_googleapis_routes](#refs-create_googleapis_routes))*
- **dns_policy**: *reference([dns_policy](#refs-dns_policy))*
- **ipv6_config**: *reference([ipv6_config](#refs-ipv6_config))*
- **network_attachments**: *reference([network_attachments](#refs-network_attachments))*
- **routers**: *reference([routers](#refs-routers))*
- **peering_config**: *reference([peering_config](#refs-peering_config))*
- **psa_configs**: *array*
  - items: *reference([psa_config](#refs-psa_config))*
- **nat_config**: *reference([nat_config](#refs-nat_config))*
- **ncc_config**: *reference([ncc_config](#refs-ncc_config))*
- **routes**: *reference([routes](#refs-routes))*
- **policy_based_routes**: *reference([policy_based_routes](#refs-policy_based_routes))*
- **vpn_config**: *object*

## Definitions

- **bgp_config**<a name="refs-bgp_config"></a>: *object*
  <br>*additional properties: false*
  - **always_compare_med**: *boolean*
  - **best_path_selection_mode**: *string*
    <br>*enum: ['LEGACY', 'STANDARD']*
  - **inter_region_cost**: *string*
    <br>*enum: ['DEFAULT', 'ADD_COST_TO_MED']*
- **create_googleapis_routes**<a name="refs-create_googleapis_routes"></a>: *object*
  - **directpath**: *boolean*
  - **directpath-6**: *boolean*
  - **private**: *boolean*
  - **private-6**: *boolean*
  - **restricted**: *boolean*
  - **restricted-6**: *boolean*
- **dns_policy**<a name="refs-dns_policy"></a>: *object*
  - **inbound**: *boolean*
  - **logging**: *boolean*
  - **outbound**: *object*
    - **private_ns**: *array*
      - items: *string*
    - **public_ns**: *array*
      - items: *string*
- **ipv6_config**<a name="refs-ipv6_config"></a>: *object*
  - **enable_ula_internal**: *boolean*
  - **internal_range**: *string*
- **nat_config**<a name="refs-nat_config"></a>: *object*
  - **`^[a-z0-9-]+$`**: *object*
    - ⁺**region**: *string*
- **ncc_config**<a name="refs-ncc_config"></a>: *object*
  - ⁺**hub**: *string*
  - **group**: *string*
- **network_attachments**<a name="refs-network_attachments"></a>: *object*
  - **`^[a-z0-9-]+$`**: *object*
    - **subnet**: *string*
    - **automatic_connection**: *boolean*
    - **description**: *string*
    - **producer_accept_lists**: *array*
      - items: *string*
    - **producer_reject_lists**: *array*
      - items: *string*
- **peering_config**<a name="refs-peering_config"></a>: *object*
  - **peer_vpc_self_link**: *string*
  - **create_remote_peer**: *boolean*
  - **export_routes**: *boolean*
  - **import_routes**: *boolean*
- **policy_based_routes**<a name="refs-policy_based_routes"></a>: *object*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
    - **filter**: *object*
      <br>*additional properties: false*
      - **dest_range**: *string*
      - **ip_protocol**: *string*
      - **src_range**: *string*
    - **labels**: *object*
      <br>*additional properties: false*
      - **`^[a-z][a-z0-9_-]{0,62}$`**: *string*
        <br>*pattern: ^[a-z0-9_-]{0,63}$*
    - **name**: *string*
    - **next_hop_ilb_ip**: *string*
    - **priority**: *number*
    - **target**: *object*
      <br>*additional properties: false*
      - **interconnect_attachment**: *string*
      - **tags**: *array*
        - items: *string*
    - **use_default_routing**: *boolean*
- **psa_config**<a name="refs-psa_config"></a>: *object*
  - **deletion_policy**: *string*
  - **ranges**: *object*
    - **`^[a-z0-9-]+$`**: *string*
  - **export_routes**: *boolean*
  - **import_routes**: *boolean*
  - **peered_domains**: *array*
    - items: *string*
  - **range_prefix**: *string*
  - **service_producer**: *string*
- **routers**<a name="refs-routers"></a>: *object*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**region**: *string*
    - ⁺**asn**: *number*
    - **custom_advertise**: *object*
      - **all_subnets**: *boolean*
      - **ip_ranges**: *object*
        - **`.*`**: *string*
- **routes**<a name="refs-routes"></a>: *object*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
    - ⁺**dest_range**: *string*
    - **name**: *string*
    - ⁺**next_hop_type**: *string*
      <br>*enum: ['gateway', 'ilb', 'instance', 'ip', 'vpn_tunnel']*
    - ⁺**next_hop**: *string*
    - **priority**: *number*
    - **tags**: *array*
      - items: *string*

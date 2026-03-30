# VLAN Attachments schema

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **admin_enabled**: *boolean*
- **dedicated_interconnect_config**: *object*
  <br>*additional properties: false*
  - **bandwidth**: *string*
    <br>*enum: ['BPS_50M', 'BPS_100M', 'BPS_200M', 'BPS_300M', 'BPS_400M', 'BPS_500M', 'BPS_1G', 'BPS_2G', 'BPS_5G', 'BPS_10G', 'BPS_20G', 'BPS_50G', 'BPS_100G', 'BPS_400G']*
  - **bgp_range**: *string*
  - **bgp_priority**: *number*
  - ⁺**interconnect**: *string*
  - ⁺**vlan_tag**: *string*
- **description**: *string*
- **ipsec_gateway_ip_ranges**: *object*
  <br>*additional properties: string*
- **mtu**: *number*
  <br>*default: 1500*
- **name**: *string*
- **partner_interconnect_config**: *object*
  <br>*additional properties: false*
  - ⁺**edge_availability_domain**: *string*
    <br>*enum: ['AVAILABILITY_DOMAIN_1', 'AVAILABILITY_DOMAIN_2', 'AVAILABILITY_DOMAIN_ANY']*
- ⁺**peer_asn**: *string*
- **region**: *string*
- ⁺**router_config**: *object*
  <br>*additional properties: false*
  - **create**: *boolean*
  - **asn**: *number*
  - **keepalive**: *number*
  - **name**: *string*
- **bgp_peer**: *object*
  <br>*additional properties: false*
  - **custom_advertise**: *object*
    <br>*additional properties: false*
    - ⁺**all_subnets**: *boolean*
    - ⁺**ip_ranges**: *object*
      <br>*additional properties: string*
  - **custom_learned_ip_ranges**: *object*
    <br>*additional properties: false*
    - **route_priority**: *number*
    - **ip_ranges**: *object*
      <br>*additional properties: string*
  - **bfd**: *object*
    <br>*additional properties: false*
    - **min_receive_interval**: *number*
    - **min_transmit_interval**: *number*
    - **multiplier**: *number*
    - **session_initialization_mode**: *string*
      <br>*enum: ['ACTIVE', 'PASSIVE']*
  - **md5_authentication_key**: *object*
    <br>*additional properties: false*
    - ⁺**name**: *string*
    - **key**: *string*
- **vpn_gateways_ip_range**: *string*
- **ncc_spoke_config**: *reference([ncc_spoke_config](#refs-ncc_spoke_config))*

## Definitions

- **ncc_spoke_config**<a name="refs-ncc_spoke_config"></a>: *object*
  - **hub**: *string*
  - **description**: *string*
  - **labels**: *object*
  - **exclude_export_ranges**: *array*
    - items: *string*
  - **include_export_ranges**: *array*
    - items: *string*
  - **group**: *string*

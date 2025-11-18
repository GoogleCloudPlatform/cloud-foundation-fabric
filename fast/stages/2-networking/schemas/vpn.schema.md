# VPN Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**name**: *string*
- **region**: *string*
- **stack_type**: *string*
  <br>*enum: ['IPV4_ONLY', 'IPV4_IPV6']*
- **peer_gateways**: *reference([peer_gateways](#refs-peer_gateways))*
- **router_config**: *reference([router_config](#refs-router_config))*
- **tunnels**: *reference([tunnels](#refs-tunnels))*
- **ncc_spoke_config**: *reference([ncc_spoke_config](#refs-ncc_spoke_config))*

## Definitions

- **peer_gateways**<a name="refs-peer_gateways"></a>: *object*
  - **`^[a-z0-9-]+$`**: *reference([peer_gateway](#refs-peer_gateway))*
- **peer_gateway**<a name="refs-peer_gateway"></a>: *object*
- **router_config**<a name="refs-router_config"></a>: *object*
  - **asn**: *number*
  - **create**: *boolean*
  - **name**: *string*
- **tunnels**<a name="refs-tunnels"></a>: *object*
  - **`^[a-z0-9-]+$`**: *reference([tunnel](#refs-tunnel))*
- **tunnel**<a name="refs-tunnel"></a>: *object*
  - **bgp_peer**: *object*
    - **address**: *string*
    - **asn**: *number*
  - **bgp_session_range**: *string*
  - **peer_external_gateway_interface**: *number*
  - **shared_secret**: *string*
  - **vpn_gateway_interface**: *number*
- **ncc_spoke_config**<a name="refs-ncc_spoke_config"></a>: *object*
  - **hub**: *string*
  - **description**: *string*
  - **labels**: *object*
  - **exclude_export_ranges**: *array*
    - items: *string*
  - **include_export_ranges**: *array*
    - items: *string*
  - **group**: *string*

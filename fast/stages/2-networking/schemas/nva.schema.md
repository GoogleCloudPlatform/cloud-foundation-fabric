# NVA Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**project_id**: *string*
- ⁺**name**: *string*
- ⁺**region**: *string*
- **auto_instance_config**: *reference([auto_instance_config](#refs-auto_instance_config))*
- **ilb_config**: *reference([ilb_config](#refs-ilb_config))*
- **instance_groups**: *object*
  <br>*additional properties: false*
  - **`^[a-z]$`**: *reference([instance_group](#refs-instance_group))*
- **ncc_ra_config**: *reference([ncc_ra_config](#refs-ncc_ra_config))*
- **bgp_config**: *reference([bgp_config](#refs-bgp_config))*

## Definitions

- **auto_instance_config**<a name="refs-auto_instance_config"></a>: *object*
  <br>*additional properties: false*
  - **image**: *string*
  - **instance_type**: *string*
  - **tags**: *array*
    - items: *string*
  - **nics**: *array*
    - items: *reference([nic](#refs-nic))*
  - **metadata**: *object*
  - **confidential_compute**: *boolean*
  - **encryption**: *object*
  - **options**: *object*
  - **shielded_config**: *object*
- **nic**<a name="refs-nic"></a>: *object*
  <br>*additional properties: false*
  - ⁺**network**: *string*
  - ⁺**subnet**: *string*
  - **routes**: *array*
    - items: *string*
  - **masquerade**: *boolean*
  - **masquerade_exclude**: *array*
    - items: *string*
  - **bgp_inbound_deny**: *array*
    - items: *string*
  - **advertise**: *array*
    - items: *string*
- **ilb_config**<a name="refs-ilb_config"></a>: *object*
  - **connection_tracking**: *object*
    <br>*additional properties: false*
    - **idle_timeout_sec**: *number*
    - **persist_conn_on_unhealthy**: *string*
      <br>*enum: ['DEFAULT_FOR_PROTOCOL', 'NEVER_PERSIST', 'ALWAYS_PERSIST']*
    - **track_per_session**: *boolean*
  - **health_check**: *object*
  - **instance_groups**: *object*
    - **`^[a-z]$`**: *reference([instance_group](#refs-instance_group))*
  - **forwarding_rules**: *array*
    - items: *reference([forwarding_rule](#refs-forwarding_rule))*
  - **session_affinity**: *string*
    <br>*enum: ['NONE', 'CLIENT_IP', 'CLIENT_IP_NO_DESTINATION', 'CLIENT_IP_PORT_PROTO', 'CLIENT_IP_PROTO']*
- **instance_group**<a name="refs-instance_group"></a>: *object*
  - **auto_create_instances**: *number*
  - **attach_instances**: *object*
- **forwarding_rule**<a name="refs-forwarding_rule"></a>: *object*
  - ⁺**network**: *string*
  - ⁺**subnet**: *string*
- **ncc_ra_config**<a name="refs-ncc_ra_config"></a>: *object*
  <br>*additional properties: false*
  - **spokes**: *array*
    - items: *object*
      <br>*additional properties: false*
      - ⁺**network**: *string*
      - ⁺**hub**: *string*
      - **group**: *string*
      - **description**: *string*
      - **labels**: *object*
        <br>*additional properties: string*
      - **site_to_site_data_transfer**: *boolean*
      - **instances**: *array*
        - items: *object*
          <br>*additional properties: false*
          - **name**: *string*
          - ⁺**vm**: *string*
          - ⁺**ip**: *string*
      - **include_import_ranges**: *array*
        - items: *string*
      - **exclude_import_ranges**: *array*
        - items: *string*
- **bgp_config**<a name="refs-bgp_config"></a>: *object*
  <br>*additional properties: false*
  - ⁺**asn**: *number*
  - **keepalive**: *number*
  - **holdtime**: *number*
  - **frr_image**: *string*

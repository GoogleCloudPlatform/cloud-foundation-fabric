# NVA Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**project_id**: *string*
- ⁺**name**: *string*
- ⁺**region**: *string*
- **auto_instance_config**: *reference([auto_instance_config](#refs-auto_instance_config))*
- **ilb_config**: *reference([ilb_config](#refs-ilb_config))*

## Definitions

- **auto_instance_config**<a name="refs-auto_instance_config"></a>: *object*
  - **image**: *string*
  - **instance_type**: *string*
  - **tags**: *array*
    - items: *string*
  - **nics**: *array*
    - items: *reference([nic](#refs-nic))*
- **nic**<a name="refs-nic"></a>: *object*
  - ⁺**network**: *string*
  - ⁺**subnet**: *string*
  - **routes**: *array*
    - items: *string*
  - **masquerade**: *boolean*
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

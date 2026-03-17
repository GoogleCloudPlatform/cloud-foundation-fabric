# DNS Zone configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**project_id**: *string*
- **description**: *string*
- **force_destroy**: *boolean*
- **domain**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **recordsets**: *reference([recordsets](#refs-recordsets))*
- **private**: *reference([private_zone](#refs-private_zone))*
- **peering**: *reference([peering_zone](#refs-peering_zone))*
- **forwarding**: *reference([forwarding_zone](#refs-forwarding_zone))*
- **public**: *reference([public_zone](#refs-public_zone))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|\$custom_roles:)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:||\$iam_principals:[a-z0-9_-]+)*
- **recordsets**<a name="refs-recordsets"></a>: *object*
  <br>*additional properties: object*
- **private_zone**<a name="refs-private_zone"></a>: *object*
  <br>*additional properties: false*
  - **service_directory_namespace**: *string*
  - ⁺**client_networks**: *array*
    - items: *string*
- **peering_zone**<a name="refs-peering_zone"></a>: *object*
  <br>*additional properties: false*
  - ⁺**peer_network**: *string*
  - ⁺**client_networks**: *array*
    - items: *string*
- **forwarding_zone**<a name="refs-forwarding_zone"></a>: *object*
  <br>*additional properties: false*
  - **forwarders**: *object*
    - **`^.*$`**: *string*
  - ⁺**client_networks**: *array*
    - items: *string*
- **public_zone**<a name="refs-public_zone"></a>: *object*
  <br>*additional properties: false*
  - **enable_logging**: *boolean*
  - **dnssec_config**: *object*
    <br>*additional properties: false*
    - **state**: *string*
    - **non_existence**: *string*
      <br>*enum: ['nsec', 'nsec3']*
    - **key_signing_key**: *object*
      <br>*additional properties: false*
      - **algorithm**: *string*
      - **key_length**: *number*
    - **zone_signing_key**: *object*
      <br>*additional properties: false*
      - **algorithm**: *string*
      - **key_length**: *number*

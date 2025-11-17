# NCC Hub Configuration

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**name**: *string*
- ⁺**project_id**: *string*
- **description**: *string*
- **export_psc**: *boolean*
- **preset_topology**: *string*
- **groups**: *reference([groups](#refs-groups))*

## Definitions

- **groups**<a name="refs-groups"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9_-]+$`**: *reference([group](#refs-group))*
- **group**<a name="refs-group"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
  - **labels**: *object*
  - **auto_accept**: *array*
    - items: *string*

# Firewall Policy Mirroring Rules

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**priority**: *number*
  - **action**: *string*
    <br>*enum: ['mirror', 'do_not_mirror', 'goto_next']*
  - **description**: *string*
  - **disabled**: *boolean*
  - **security_profile_group**: *string*
  - **target_tags**: *array*
    - items: *string*
  - **tls_inspect**: *boolean*
  - **match**: *object*
    <br>*additional properties: false*
    - **destination_ranges**: *array*
      - items: *string*
    - **source_ranges**: *array*
      - items: *string*
    - **source_tags**: *array*
      - items: *string*
    - **layer4_configs**: *array*
      - items: *object*
        <br>*additional properties: false*
        - **protocol**: *string*
        - **ports**: *array*

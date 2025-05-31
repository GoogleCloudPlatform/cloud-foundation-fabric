# Firewall Rules

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**priority**: *number*
  - **action**: *string*
    <br>*enum: ['allow', 'deny', 'goto_next', 'apply_security_profile_group']*
  - **description**: *string*
  - **disabled**: *boolean*
  - **enable_logging**: *boolean*
  - **security_profile_group**: *string*
  - **target_resources**: *array*
    - items: *string*
  - **target_service_accounts**: *array*
    - items: *string*
  - **target_tags**: *array*
    - items: *string*
  - **tls_inspect**: *boolean*
  - **match**: *object*
    <br>*additional properties: false*
    - **address_groups**: *array*
      - items: *string*
    - **fqdns**: *array*
      - items: *string*
    - **region_codes**: *array*
      - items: *string*
    - **threat_intelligences**: *array*
      - items: *string*
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

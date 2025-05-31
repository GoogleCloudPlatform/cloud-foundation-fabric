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
    <br>*enum: ['allow', 'deny', 'goto_next', 'apply_security_profile_group']*, *pattern: None*
  - **description**: *string*
    <br>*pattern: None*
  - **disabled**: *boolean*
  - **enable_logging**: *boolean*
  - **security_profile_group**: *string*
    <br>*pattern: None*
  - **target_resources**: *array*
    - items: *string*
      <br>*pattern: None*
  - **target_service_accounts**: *array*
    - items: *string*
      <br>*pattern: None*
  - **target_tags**: *array*
    - items: *string*
      <br>*pattern: None*
  - **tls_inspect**: *boolean*
  - **match**: *object*
    <br>*additional properties: false*
    - **address_groups**: *array*
      - items: *string*
        <br>*pattern: None*
    - **fqdns**: *array*
      - items: *string*
        <br>*pattern: None*
    - **region_codes**: *array*
      - items: *string*
        <br>*pattern: None*
    - **threat_intelligences**: *array*
      - items: *string*
        <br>*pattern: None*
    - **destination_ranges**: *array*
      - items: *string*
        <br>*pattern: None*
    - **source_ranges**: *array*
      - items: *string*
        <br>*pattern: None*
    - **source_tags**: *array*
      - items: *string*
        <br>*pattern: None*
    - **layer4_configs**: *array*
      - items: *object*
        <br>*additional properties: false*
        - **protocol**: *string*
          <br>*pattern: None*
        - **ports**: *array*

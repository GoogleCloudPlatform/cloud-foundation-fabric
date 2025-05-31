# Firewall Rules

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **egress**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*
- **ingress**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - **deny**: *boolean*
  - **description**: *string*
    <br>*pattern: None*
  - **destination_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
  - **disabled**: *boolean*
  - **enable_logging**: *object*
    <br>*additional properties: false*
    - **include_metadata**: *boolean*
  - **priority**: *number*
  - **source_ranges**: *array*
    - items: *string*
      <br>*pattern: None*
  - **sources**: *array*
    - items: *string*
      <br>*pattern: None*
  - **targets**: *array*
    - items: *string*
      <br>*pattern: None*
  - **use_service_accounts**: *boolean*
  - **rules**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **protocol**: *string*
        <br>*pattern: None*
      - **ports**: *array*
        - items: *(integer|string)*
          <br>*pattern: `^[0-9]+(?:-[0-9]+)?$`*

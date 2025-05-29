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
  - **destination_ranges**: *array*
    - items: *string*
  - **disabled**: *boolean*
  - **enable_logging**: *object*
    <br>*additional properties: false*
    - **include_metadata**: *boolean*
  - **priority**: *number*
  - **source_ranges**: *array*
    - items: *string*
  - **sources**: *array*
    - items: *string*
  - **targets**: *array*
    - items: *string*
  - **use_service_accounts**: *boolean*
  - **rules**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **protocol**: *string*
      - **ports**: *array*
        - items: *number*
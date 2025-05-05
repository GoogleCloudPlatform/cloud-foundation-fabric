# Firewall Rules

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **egress**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*
- **ingress**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*no additional properties allowed*
  - **deny**: *boolean*
  - **description**: *string*
  - **destination_ranges**: *array*
    - items: *string*
  - **disabled**: *boolean*
  - **enable_logging**: *object*
    <br>*no additional properties allowed*
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
      <br>*no additional properties allowed*
      - **protocol**: *string*
      - **ports**: *array*
        - items: *number*
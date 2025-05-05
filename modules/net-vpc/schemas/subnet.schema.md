# Subnet

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **active**: *boolean*
- **description**: *string*
- **enable_private_access**: *boolean*
- **allow_subnet_cidr_routes_overlap**: *boolean*
- **flow_logs_config**: *object*
  <br>*no additional properties allowed*
  - **aggregation_interval**: *string*
  - **filter_expression**: *string*
  - **flow_sampling**: *number*
  - **metadata**: *string*
  - **metadata_fields**: *array*
    - items: *string*
- **global**: *boolean*
- ⁺**ip_cidr_range**: *string*
- **ipv6**: *object*
  <br>*no additional properties allowed*
  - **access_type**: *string*
- **name**: *string*
- ⁺**region**: *string*
- **psc**: *boolean*
- **proxy_only**: *boolean*
- **secondary_ip_ranges**: *object*
  *additional properties: String*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*no additional properties allowed*
  - **`^roles/`**: *array*
    - items: *string*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*no additional properties allowed*
    - **members**: *array*
      - items: *string*
    - **role**: *string*
    - **condition**: *object*
      <br>*no additional properties allowed*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*no additional properties allowed*
    - **member**: *string*
    - **role**: *string*
    - **condition**: *object*
      <br>*no additional properties allowed*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
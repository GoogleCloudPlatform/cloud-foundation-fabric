# Subnet

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **active**: *boolean*
- **description**: *string*
  <br>*pattern: None*
- **enable_private_access**: *boolean*
- **allow_subnet_cidr_routes_overlap**: *boolean*
- **flow_logs_config**: *object*
  <br>*additional properties: false*
  - **aggregation_interval**: *string*
    <br>*pattern: None*
  - **filter_expression**: *string*
    <br>*pattern: None*
  - **flow_sampling**: *number*
  - **metadata**: *string*
    <br>*pattern: None*
  - **metadata_fields**: *array*
    - items: *string*
      <br>*pattern: None*
- **global**: *boolean*
- ⁺**ip_cidr_range**: *string*
  <br>*pattern: None*
- **ipv6**: *object*
  <br>*additional properties: false*
  - **access_type**: *string*
    <br>*pattern: None*
- **name**: *string*
  <br>*pattern: None*
- ⁺**region**: *string*
  <br>*pattern: None*
- **psc**: *boolean*
- **proxy_only**: *boolean*
- **secondary_ip_ranges**: *object*
  *additional properties: String*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|ro|rw)*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|ro|rw)*
    - **role**: *string*
      <br>*pattern: ^roles/*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
        <br>*pattern: None*
      - ⁺**title**: *string*
        <br>*pattern: None*
      - **description**: *string*
        <br>*pattern: None*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|ro|rw)*
    - **role**: *string*
      <br>*pattern: ^roles/*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
        <br>*pattern: None*
      - ⁺**title**: *string*
        <br>*pattern: None*
      - **description**: *string*
        <br>*pattern: None*

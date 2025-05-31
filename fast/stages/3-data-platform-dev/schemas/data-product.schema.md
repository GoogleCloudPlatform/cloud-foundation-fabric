# Data Product

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **automation**: *object*
  <br>*additional properties: false*
  - **location**: *string*
  - **impersonation_principals**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **exposure_layer**: *object*
  <br>*additional properties: false*
  - **bigquery**: *object*
    <br>*additional properties: false*
    - **datasets**: *object*
      - **`^[a-z][a-z0-9_]+$`**: *object*
        <br>*additional properties: false*
        - **encryption_key**: *string*
        - **location**: *string*
    - **iam**: *reference([iam](#refs-iam))*
  - **storage**: *object*
    <br>*additional properties: false*
    - **buckets**: *object*
      - **`^[a-z][a-z0-9-]+$`**: *object*
        <br>*additional properties: false*
        - **encryption_key**: *string*
        - **location**: *string*
        - **storage_class**: *string*
    - **iam**: *reference([iam](#refs-iam))*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
    - **name**: *string*
- **services**: *array*
  - items: *string*
- **shared_vpc_service_config**: *object*
  <br>*additional properties: false*
  - ⁺**host_project**: *string*
  - **network_users**: *array*
    - items: *string*
  - **service_agent_iam**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
  - **service_iam_grants**: *array*
    - items: *string*
- **short_name**: *string*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|[a-z_]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z])*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z])*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*

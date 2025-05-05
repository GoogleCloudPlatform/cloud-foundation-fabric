# Data Product

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **automation**: *object*
  <br>*no additional properties allowed*
  - **location**: *string*
  - **impersonation_principals**: *array*
    - items: *string*
- **exposure_layer**: *object*
  <br>*no additional properties allowed*
  - **bigquery**: *object*
    <br>*no additional properties allowed*
    - **datasets**: *object*
      - **`^[a-z][a-z0-9_]+$`**: *object*
        <br>*no additional properties allowed*
        - **encryption_key**: *string*
        - **location**: *string*
    - **iam**: *reference([iam](#refs-iam))*
  - **storage**: *object*
    <br>*no additional properties allowed*
    - **buckets**: *object*
      - **`^[a-z][a-z0-9-]+$`**: *object*
        <br>*no additional properties allowed*
        - **encryption_key**: *string*
        - **location**: *string*
        - **storage_class**: *string*
    - **iam**: *reference([iam](#refs-iam))*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **service_accounts**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - **description**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
    - **name**: *string*
- **services**: *array*
  - items: *string*
- **shared_vpc_service_config**: *object*
  <br>*no additional properties allowed*
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
  <br>*no additional properties allowed*
  - **`^(?:roles/|[a-z_]+)`**: *array*
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
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z]+[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
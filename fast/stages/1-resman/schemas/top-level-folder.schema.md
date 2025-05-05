# Folder

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **automation**: *object*
  <br>*no additional properties allowed*
  - **environment_name**: *string*
  - **sa_impersonation_principals**: *array*
    - items: *string*
  - **short_name**: *string*
- **contacts**: *object*
  <br>*no additional properties allowed*
  - **`@`**: *array*
    - items: *string*
- **factories_config**: *object*
  <br>*no additional properties allowed*
  - **org_policies**: *string*
- **firewall_policy**: *object*
  <br>*no additional properties allowed*
  - ⁺**name**: *string*
  - ⁺**policy**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **is_fast_context**: *boolean*
- **logging_data_access**: *object*
  <br>*no additional properties allowed*
  - **`^(?:[a-z_-]+)\.googleapis\.com$`**: *object*
    <br>*no additional properties allowed*
    - **`^(?:DATA_READ|DATA_WRITE|ADMIN_READ)$`**: *object*
      <br>*no additional properties allowed*
      - **exempted_members**: *array*
        - items: *string*
- **logging_exclusions**: *object*
  *additional properties: String*
- **logging_settings**: *object*
  <br>*no additional properties allowed*
  - **disable_default_sink**: *boolean*
  - **storage_location**: *string*
- **logging_sinks**: *object*
  *additional properties: Object*
- **name**: *string*
- **org_policies**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z]+\.`**: *object*
    - **inherit_from_parent**: *boolean*
    - **reset**: *boolean*
    - **rules**: *array*
      - items: *object*
        <br>*no additional properties allowed*
        - **allow**: *object*
          <br>*no additional properties allowed*
          - **all**: *boolean*
          - **values**: *array*
            - items: *string*
        - **deny**: *object*
          <br>*no additional properties allowed*
          - **all**: *boolean*
          - **values**: *array*
            - items: *string*
        - **enforce**: *boolean*
        - **condition**: *object*
          <br>*no additional properties allowed*
          - **description**: *string*
          - **expression**: *string*
          - **location**: *string*
          - **title**: *string*
- **parent_id**: *string*
- **tag_bindings**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *string*

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
  - **`^[a-z]+[a-z-]+$`**: *array*
    - items: *string*
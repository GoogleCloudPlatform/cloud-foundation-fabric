# Folder

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **automation**: *object*
  <br>*additional properties: false*
  - **environment_name**: *string*
  - **sa_impersonation_principals**: *array*
    - items: *string*
  - **short_name**: *string*
- **contacts**: *object*
  <br>*additional properties: false*
  - **`@`**: *array*
    - items: *string*
      <br>*pattern: ^(?:ALL|SUSPENSION|SECURITY|TECHNICAL|BILLING|LEGAL|PRODUCT_UPDATES)$*
- **factories_config**: *object*
  <br>*additional properties: false*
  - **org_policies**: *string*
- **firewall_policy**: *object*
  <br>*additional properties: false*
  - ⁺**name**: *string*
  - ⁺**policy**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **is_fast_context**: *boolean*
- **logging_data_access**: *object*
  <br>*additional properties: false*
  - **`^(?:[a-z_-]+)\.googleapis\.com$`**: *object*
    <br>*additional properties: false*
    - **`^(?:DATA_READ|DATA_WRITE|ADMIN_READ)$`**: *object*
      <br>*additional properties: false*
      - **exempted_members**: *array*
        - items: *string*
          <br>*pattern: @*
- **logging_exclusions**: *object*
  *additional properties: String*
- **logging_settings**: *object*
  <br>*additional properties: false*
  - **disable_default_sink**: *boolean*
  - **storage_location**: *string*
- **logging_sinks**: *object*
  *additional properties: Object*
- **name**: *string*
- **org_policies**: *object*
  <br>*additional properties: false*
  - **`^[a-z]+\.`**: *object*
    - **inherit_from_parent**: *boolean*
    - **reset**: *boolean*
    - **rules**: *array*
      - items: *object*
        <br>*additional properties: false*
        - **allow**: *object*
          <br>*additional properties: false*
          - **all**: *boolean*
          - **values**: *array*
            - items: *string*
        - **deny**: *object*
          <br>*additional properties: false*
          - **all**: *boolean*
          - **values**: *array*
            - items: *string*
        - **enforce**: *boolean*
        - **condition**: *object*
          <br>*additional properties: false*
          - **description**: *string*
          - **expression**: *string*
          - **location**: *string*
          - **title**: *string*
- **parent_id**: *string*
- **tag_bindings**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|[a-z_]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|project-factory|project-factory-dev|project-factory-prod|networking|security|vpcsc|self)*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|project-factory|project-factory-dev|project-factory-prod|networking|security|vpcsc|self)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*
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
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|project-factory|project-factory-dev|project-factory-prod|networking|security|vpcsc|self)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z-]+$`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*

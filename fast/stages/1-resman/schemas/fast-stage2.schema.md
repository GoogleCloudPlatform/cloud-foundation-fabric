# FAST stage 2

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **short_name**: *string*
- **cicd_config**: *object*
  <br>*additional properties: false*
  - ⁺**identity_provider**: *string*
  - ⁺**repository**: *object*
    <br>*additional properties: false*
    - ⁺**name**: *string*
    - **branch**: *string*
    - **type**: *string*
    <br>*default: github*, *enum: ['github', 'gitlab']*
- **folder_config**: *object*
  <br>*additional properties: false*
  - ⁺**name**: *string*
  - **create_env_folders**: *boolean*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
  - **org_policies**: *object*
    <br>*additional properties: false*
    - **`^[a-z]+\.`**: *object*
      <br>*additional properties: false*
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
- **organization_config**: *object*
  <br>*additional properties: false*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **stage3_config**: *object*
  <br>*additional properties: false*
  - **iam_admin_delegated**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **environment**: *string*
      - **principal**: *string*
  - **iam_viewer**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **environment**: *string*
      - **principal**: *string*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|[a-z_]+)`**: *array*
    - items: *string*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
    - **role**: *string*
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
    - **role**: *string*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z-]+$`**: *array*
    - items: *string*
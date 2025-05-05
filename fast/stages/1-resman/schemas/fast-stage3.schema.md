# FAST stage 3

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- ⁺**short_name**: *string*
- ⁺**environment**: *string*
<br>, *enum: ['dev', 'prod']*
- **cicd_config**: *object*
  <br>*no additional properties allowed*
  - ⁺**identity_provider**: *string*
  - ⁺**repository**: *object*
    <br>*no additional properties allowed*
    - ⁺**name**: *string*
    - **branch**: *string*
    - **type**: *string*
<br>*default: github*, *enum: ['github', 'gitlab']*
- **folder_config**: *object*
  <br>*no additional properties allowed*
  - ⁺**name**: *string*
  - **parent_id**: *string*
  - **tag_bindings**: *object*
    <br>*no additional properties allowed*
    - **`^[a-z0-9_-]+$`**: *string*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
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
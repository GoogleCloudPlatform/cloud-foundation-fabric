# FAST stage 2

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **short_name**: *string*
  <br>*pattern: None*
- **cicd_config**: *object*
  <br>*additional properties: false*
  - ⁺**identity_provider**: *string*
    <br>*pattern: None*
  - ⁺**repository**: *object*
    <br>*additional properties: false*
    - ⁺**name**: *string*
      <br>*pattern: None*
    - **branch**: *string*
      <br>*pattern: None*
    - **type**: *string*
      <br>*default: github*, *enum: ['github', 'gitlab']*, *pattern: None*
- **folder_config**: *object*
  <br>*additional properties: false*
  - ⁺**name**: *string*
    <br>*pattern: None*
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
                <br>*pattern: None*
          - **deny**: *object*
            <br>*additional properties: false*
            - **all**: *boolean*
            - **values**: *array*
              - items: *string*
                <br>*pattern: None*
          - **enforce**: *boolean*
          - **condition**: *object*
            <br>*additional properties: false*
            - **description**: *string*
              <br>*pattern: None*
            - **expression**: *string*
              <br>*pattern: None*
            - **location**: *string*
              <br>*pattern: None*
            - **title**: *string*
              <br>*pattern: None*
  - **parent_id**: *string*
    <br>*pattern: None*
  - **tag_bindings**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9_-]+$`**: *string*
      <br>*pattern: None*
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
        <br>*pattern: None*
      - **principal**: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
  - **iam_viewer**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **environment**: *string*
        <br>*pattern: None*
      - **principal**: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*

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
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|[a-z])*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
        <br>*pattern: None*
      - ⁺**title**: *string*
        <br>*pattern: None*
      - **description**: *string*
        <br>*pattern: None*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z]+[a-z-]+$`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|[a-z_]+)*

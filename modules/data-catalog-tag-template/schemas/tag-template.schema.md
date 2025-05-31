# Data Catalog Tag Template

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **display_name**: *string*
  <br>*pattern: None*
- **force_delete**: *boolean*
- **region**: *string*
  <br>*pattern: None*
- **fields**: *object*
  <br>*additional properties: false*
  - **display_name**: *string*
    <br>*pattern: None*
  - **description**: *string*
    <br>*pattern: None*
  - **is_required**: *boolean*
  - **order**: *number*
  - **type**: *object*
    <br>*additional properties: false*
    - **primitive_type**: *string*
      <br>*enum: ['DOUBLE', 'STRING', 'BOOL', 'TIMESTAMP']*, *pattern: None*
    - **enum_type_values**: *array*
      - items: *string*
        <br>*pattern: None*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
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
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])*
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
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])`**: *array*
    - items: *string*
      <br>*pattern: ^roles/*

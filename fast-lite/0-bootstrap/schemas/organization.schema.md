# Organization

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **id**: *string*
- **contacts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *array*
    - items: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **logging**: *object*
  <br>*additional properties: false*
  - **storage_location**: *string*
  - **sinks**: *object*
    <br>*additional properties: false*
    - **`^[a-z][a-z0-9-]+$`**: *object*
      <br>*additional properties: false*
      - **description**: *string*
      - **destination**: *string*
      - **exclusions**: *object*
      - **filter**: *string*
      - **type**: *string*
        <br>*default: logging*, *enum: ['bigquery', 'logging', 'project', 'pubsub', 'storage']*
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
- **tags**: *object*
  *additional properties: Object*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
    - items: *string*
      <br>*pattern: ^(?:\$[a-z_-]+:|domain:|group:|mdb:|serviceAccount:|user:|principal:|principalSet:)*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**members**: *array*
      - items: *string*
        <br>*pattern: ^(?:\$[a-z_-]+:|domain:|group:|mdb:|serviceAccount:|user:|principal:|principalSet:)*
    - ⁺**role**: *string*
      <br>*pattern: ^roles/*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**member**: *string*
      <br>*pattern: ^(?:\$[a-z_-]+:|domain:|group:|serviceAccount:|user:|principal:|principalSet:)*
    - ⁺**role**: *string*
      <br>*pattern: ^[a-zA-Z0-9_/\.]+$*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:\$[a-z_-]+:|domain:|group:|serviceAccount:|user:|principal:|principalSet:)`**: *array*
    - items: *string*
      <br>*pattern: ^roles/*

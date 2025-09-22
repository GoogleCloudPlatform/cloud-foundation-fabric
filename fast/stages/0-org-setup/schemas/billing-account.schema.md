# Billing Account

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**id**: *string*
- **iam**: *object*
  <br>*additional properties: false*
  - **`^roles/`**: *array*
    - items: *string*
      <br>*pattern: ^(?:\$[a-z_-]+:|domain:|group:|mdb:|serviceAccount:|user:|principal:|principalSet:)*
- **iam_bindings**: *object*
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
- **iam_bindings_additive**: *object*
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
- **iam_by_principals**: *object*
  <br>*additional properties: false*
  - **`^(?:\$[a-z_-]+:|domain:|group:|serviceAccount:|user:|principal:|principalSet:)`**: *array*
    - items: *string*
      <br>*pattern: ^roles/*
- **logging_sinks**: *object*
  <br>*additional properties: false*
  - **`^[a-z][a-z0-9_-]+`**: *object*
    <br>*additional properties: false*
    - ⁺**destination**: *string*
    - ⁺**type**: *string*
      <br>*enum: ['bigquery', 'logging', 'project', 'pubsub', 'storage']*
    - **bq_partitioned_table**: *boolean*
    - **description**: *string*
    - **disabled**: *boolean*
    - **exclusions**: *object*
      <br>*additional properties: false*
      - **`^[a-z][a-z0-9_-]+`**: *object*
        <br>*additional properties: false*
        - ⁺**filter**: *string*
        - **description**: *string*
        - **disabled**: *boolean*
    - **filter**: *string*
- **billing_export**: *object*
  <br>*additional properties: false*
  - ⁺**project_id**: *string*
  - ⁺**dataset_name**: *string*
  - **location**: *string*
  - **friendly_name**: *string*

## Definitions



# BigQuery Dataset

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **access**: *object*
  <br>*additional properties: object*
- **access_identities**: *object*
  <br>*additional properties: string*
- **authorized_datasets**: *array*
  - items: *object*
    <br>*additional properties: false*
    - ⁺**dataset_id**: *string*
    - ⁺**project_id**: *string*
- **authorized_routines**: *array*
  - items: *object*
    <br>*additional properties: false*
    - ⁺**project_id**: *string*
    - ⁺**dataset_id**: *string*
    - ⁺**routine_id**: *string*
- **authorized_views**: *array*
  - items: *object*
    <br>*additional properties: false*
    - ⁺**dataset_id**: *string*
    - ⁺**project_id**: *string*
    - ⁺**table_id**: *string*
- **dataset_access**: *boolean*
- **description**: *string*
- **encryption_key**: *string*
- **friendly_name**: *string*
- **iam**: *object*
  <br>*additional properties: array*
- **iam_bindings**: *object*
  <br>*additional properties: object*
- **iam_bindings_additive**: *object*
  <br>*additional properties: object*
- **iam_by_principals**: *object*
  <br>*additional properties: array*
- **id**: *string*
- **labels**: *object*
  <br>*additional properties: string*
- **location**: *string*
- **materialized_views**: *object*
  <br>*additional properties: object*
- **options**: *object*
  <br>*additional properties: false*
  - **default_collation**: *string*
  - **default_table_expiration_ms**: *number*
  - **default_partition_expiration_ms**: *number*
  - **delete_contents_on_destroy**: *boolean*
  - **is_case_insensitive**: *boolean*
  - **max_time_travel_hours**: *number*
  - **storage_billing_model**: *string*
- **project_id**: *string*
- **routines**: *object*
  <br>*additional properties: object*
- **tables**: *object*
  <br>*additional properties: object*
- **tag_bindings**: *object*
  <br>*additional properties: string*
- **views**: *object*
  <br>*additional properties: object*

## Definitions

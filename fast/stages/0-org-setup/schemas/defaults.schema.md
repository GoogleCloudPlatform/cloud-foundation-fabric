# Bootstrap Defaults

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **global**: *object*
  <br>*additional properties: false*
  - ⁺**billing_account**: *string*
  - **locations**: *object*
    <br>*additional properties: false*
    - **bigquery**: *string*
      <br>*default: eu*
    - **logging**: *string*
      <br>*default: global*
    - **pubsub**: *array*
      - items: *string*
    - **storage**: *string*
      <br>*default: eu*
  - ⁺**organization**: *object*
    <br>*additional properties: false*
    - **customer_id**: *string*
    - **domain**: *string*
    - ⁺**id**: *integer*
- **projects**: *object*
  <br>*additional properties: false*
  - **defaults**: *object*
    <br>*additional properties: false*
    - **billing_account**: *string*
    - **bucket**: *object*
      <br>*additional properties: false*
      - **force_destroy**: *boolean*
    - **contacts**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **deletion_policy**: *string*
      <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
    - **labels**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **metric_scopes**: *array*
      - items: *string*
    - **parent**: *string*
    - **prefix**: *string*
    - **project_reuse**: *object*
      <br>*additional properties: false*
      - **use_data_source**: *boolean*
      - **attributes**: *object*
        <br>*additional properties: false*
        - ⁺**name**: *string*
        - ⁺**number**: *number*
        - **services_enabled**: *array*
          - items: *string*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **services**: *array*
      - items: *string*
    - **shared_vpc_service_config**: *object*
      <br>*additional properties: false*
      - ⁺**host_project**: *string*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
      - **network_users**: *array*
        - items: *string*
      - **service_agent_iam**: *object*
        *additional properties: Array*
      - **service_agent_subnet_iam**: *object*
        *additional properties: Array*
      - **service_iam_grants**: *array*
        - items: *string*
      - **network_subnet_users**: *object*
        *additional properties: Array*
    - **storage_location**: *string*
    - **tag_bindings**: *object*
      *additional properties: String*
    - **service_accounts**: *object*
      *additional properties: Object*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
    - **logging_data_access**: *object*
      *additional properties: Object*
    - **bigquery_location**: *string*
  - **overrides**: *object*
    <br>*additional properties: false*
    - **billing_account**: *string*
    - **bucket**: *object*
      <br>*additional properties: false*
      - **force_destroy**: *boolean*
    - **contacts**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **deletion_policy**: *string*
      <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
    - **parent**: *string*
    - **prefix**: *string*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **storage_location**: *string*
    - **tag_bindings**: *object*
      *additional properties: String*
    - **service_accounts**: *object*
      *additional properties: Object*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
    - **logging_data_access**: *object*
      *additional properties: Object*
    - **bigquery_location**: *string*
- **context**: *object*
  <br>*additional properties: false*
  - **iam_principals**: *object*
    *additional properties: String*
- **output_files**: *object*
  <br>*additional properties: false*
  - **local_path**: *string*
  - **storage_bucket**: *string*
  - **providers**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9][a-z0-9_-]+$`**: *object*
      <br>*additional properties: false*
      - ⁺**bucket**: *string*
      - **prefix**: *string*
      - ⁺**service_account**: *string*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|\$custom_roles:)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:||\$iam_principals:[a-z0-9_-]+)*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
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
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*

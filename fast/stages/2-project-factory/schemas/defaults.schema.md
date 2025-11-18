# Bootstrap Defaults

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

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
    - **locations**: *object*
      <br>*additional properties: false*
      - **bigquery**: *string*
      - **logging**: *string*
      - **storage**: *string*
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
    - **service_accounts**: *object*
      <br>*additional properties: object*
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
        <br>*additional properties: array*
      - **service_agent_subnet_iam**: *object*
        <br>*additional properties: array*
      - **service_iam_grants**: *array*
        - items: *string*
      - **network_subnet_users**: *object*
        <br>*additional properties: array*
    - **tag_bindings**: *object*
      <br>*additional properties: string*
    - **universe**: *object*
      <br>*additional properties: false*
      - ⁺**prefix**: *string*
      - **unavailable_service_identities**: *array*
        - items: *string*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
  - **merges**: *object*
    <br>*additional properties: false*
    - **contacts**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **labels**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **metric_scopes**: *array*
      - items: *string*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **service_accounts**: *object*
      <br>*additional properties: object*
    - **services**: *array*
      - items: *string*
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
    - **locations**: *object*
      <br>*additional properties: false*
      - **bigquery**: *string*
      - **logging**: *string*
      - **storage**: *string*
    - **parent**: *string*
    - **prefix**: *string*
    - **service_accounts**: *object*
      <br>*additional properties: object*
    - **service_encryption_key_ids**: *object*
      <br>*additional properties: false*
      - **`^[a-z0-9_-]+$`**: *array*
        - items: *string*
    - **services**: *array*
      - items: *string*
    - **tag_bindings**: *object*
      <br>*additional properties: string*
    - **universe**: *object*
      <br>*additional properties: false*
      - ⁺**prefix**: *string*
      - **unavailable_service_identities**: *array*
        - items: *string*
    - **vpc_sc**: *object*
      - ⁺**perimeter_name**: *string*
      - **is_dry_run**: *boolean*
- **context**: *object*
  <br>*additional properties: false*
  - **custom_roles**: *object*
    <br>*additional properties: string*
  - **email_addresses**: *object*
    <br>*additional properties: string*
  - **folder_ids**: *object*
    <br>*additional properties: string*
  - **kms_keys**: *object*
    <br>*additional properties: string*
  - **iam_principals**: *object*
    <br>*additional properties: string*
  - **locations**: *object*
    <br>*additional properties: string*
  - **notification_channels**: *object*
    <br>*additional properties: string*
  - **project_ids**: *object*
    <br>*additional properties: string*
  - **service_account_ids**: *object*
    <br>*additional properties: string*
  - **tag_keys**: *object*
    <br>*additional properties: string*
  - **tag_values**: *object*
    <br>*additional properties: string*
  - **vpc_host_projects**: *object*
    <br>*additional properties: string*
  - **vpc_sc_perimeters**: *object*
    <br>*additional properties: string*
- **output_files**: *object*
  <br>*additional properties: false*
  - **local_path**: *string*
  - **providers_template_path**: *string*
    <br>*default: assets/providers.tf.tpl*
  - **storage_bucket**: *string*
  - **providers_pattern**: *object*
    <br>*additional properties: false*
    - ⁺**service_accounts_match**: *object*
      <br>*additional properties: false*
      - **ro**: *string*
      - **rw**: *string*
    - ⁺**storage_bucket**: *string*
    - **storage_folders_create**: *boolean*
  - **providers**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9][a-z0-9_-]+$`**: *object*
      <br>*additional properties: false*
      - ⁺**service_account**: *string*
      - **set_prefix**: *boolean*
      - ⁺**storage_bucket**: *string*

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

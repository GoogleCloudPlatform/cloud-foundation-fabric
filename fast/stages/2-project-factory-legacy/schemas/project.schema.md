# Project

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **automation**: *object*
  <br>*additional properties: false*
  - **prefix**: *string*
  - ⁺**project**: *string*
  - **bucket**: *reference([bucket](#refs-bucket))*
  - **service_accounts**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9-]+$`**: *object*
      <br>*additional properties: false*
      - **description**: *string*
      - **iam**: *reference([iam](#refs-iam))*
      - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
      - **iam_billing_roles**: *reference([iam_billing_roles](#refs-iam_billing_roles))*
      - **iam_folder_roles**: *reference([iam_folder_roles](#refs-iam_folder_roles))*
      - **iam_organization_roles**: *reference([iam_organization_roles](#refs-iam_organization_roles))*
      - **iam_project_roles**: *reference([iam_project_roles](#refs-iam_project_roles))*
      - **iam_sa_roles**: *reference([iam_sa_roles](#refs-iam_sa_roles))*
      - **iam_storage_roles**: *reference([iam_storage_roles](#refs-iam_storage_roles))*
- **billing_account**: *string*
- **billing_budgets**: *array*
  - items: *string*
- **buckets**: *reference([buckets](#refs-buckets))*
- **contacts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *array*
    - items: *string*
- **deletion_policy**: *string*
  <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **labels**: *object*
- **log_buckets**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *reference([log_bucket](#refs-log_bucket))*
- **metric_scopes**: *array*
  - items: *string*
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
- **quotas**: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**service**: *string*
    - ⁺**quota_id**: *string*
    - ⁺**preferred_value**: *number*
    - **dimensions**: *object*
      *additional properties: String*
    - **justification**: *string*
    - **contact_email**: *string*
    - **annotations**: *object*
      *additional properties: String*
    - **ignore_safety_checks**: *string*
      <br>*enum: ['QUOTA_DECREASE_BELOW_USAGE', 'QUOTA_DECREASE_PERCENTAGE_TOO_HIGH', 'QUOTA_SAFETY_CHECK_UNSPECIFIED']*
- **parent**: *string*
- **prefix**: *string*
- **project_reuse**: *object*
  <br>*additional properties: false*
  - **use_data_source**: *boolean*
  - **attributes**: *object*
    - ⁺**name**: *string*
    - ⁺**number**: *number*
    - **services_enabled**: *array*
      - items: *string*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **display_name**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_self_roles**: *array*
      - items: *string*
    - **iam_project_roles**: *reference([iam_project_roles](#refs-iam_project_roles))*
    - **iam_sa_roles**: *reference([iam_sa_roles](#refs-iam_sa_roles))*
- **service_encryption_key_ids**: *object*
  <br>*additional properties: false*
  - **`^[a-z-]+\.googleapis\.com$`**: *array*
    - items: *string*
- **services**: *array*
  - items: *string*
    <br>*pattern: ^[a-z-]+\.googleapis\.com$*
- **shared_vpc_host_config**: *object*
  <br>*additional properties: false*
  - ⁺**enabled**: *boolean*
  - **service_projects**: *array*
    - items: *string*
- **shared_vpc_service_config**: *object*
  <br>*additional properties: false*
  - ⁺**host_project**: *string*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **network_users**: *array*
    - items: *string*
  - **service_agent_iam**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
  - **service_agent_subnet_iam**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
  - **service_iam_grants**: *array*
    - items: *string*
  - **network_subnet_users**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
- **tag_bindings**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*
- **tags**: *object*
  *additional properties: Object*
- **universe**: *object*
  <br>*additional properties: false*
  - **prefix**: *string*
- **vpc_sc**: *object*
  - ⁺**perimeter_name**: *string*
  - **is_dry_run**: *boolean*

## Definitions

- **bucket**<a name="refs-bucket"></a>: *object*
  <br>*additional properties: false*
  - **name**: *string*
  - **description**: *string*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **force_destroy**: *boolean*
  - **labels**: *object*
    *additional properties: String*
  - **location**: *string*
  - **managed_folders**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9][a-zA-Z0-9_/-]+$`**: *object*
      <br>*additional properties: false*
      - **force_destroy**: *boolean*
      - **iam**: *reference([iam](#refs-iam))*
      - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **prefix**: *string*
  - **storage_class**: *string*
  - **uniform_bucket_level_access**: *boolean*
  - **versioning**: *boolean*
- **buckets**<a name="refs-buckets"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *reference([bucket](#refs-bucket))*
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
- **iam_billing_roles**<a name="refs-iam_billing_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_folder_roles**<a name="refs-iam_folder_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_organization_roles**<a name="refs-iam_organization_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_project_roles**<a name="refs-iam_project_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:[a-z0-9-]|\$project_ids:[a-z0-9_-])+$`**: *array*
    - items: *string*
- **iam_sa_roles**<a name="refs-iam_sa_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:\$service_account_ids:|projects/)`**: *array*
    - items: *string*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **log_bucket**<a name="refs-log_bucket"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
  - **kms_key_name**: *string*
  - **location**: *string*
  - **log_analytics**: *object*
    <br>*additional properties: false*
    - **enable**: *boolean*
    - **dataset_link_id**: *string*
    - **description**: *string*
  - **retention**: *number*

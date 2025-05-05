# Project

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **automation**: *object*
  <br>*no additional properties allowed*
  - ⁺**project**: *string*
  - **bucket**: *reference([bucket](#refs-bucket))*
  - **service_accounts**: *object*
    <br>*no additional properties allowed*
    - **`^[a-z0-9-]+$`**: *object*
      <br>*no additional properties allowed*
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
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *array*
    - items: *string*
- **deletion_policy**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **labels**: *object*
- **metric_scopes**: *array*
  - items: *string*
- **name**: *string*
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
- **parent**: *string*
- **prefix**: *string*
- **project_reuse**: *object*
  <br>*no additional properties allowed*
  - **use_data_source**: *boolean*
  - **project_attributes**: *object*
    - ⁺**name**: *string*
    - ⁺**number**: *number*
    - **services_enabled**: *array*
      - items: *string*
- **service_accounts**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - **display_name**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_self_roles**: *array*
      - items: *string*
    - **iam_project_roles**: *reference([iam_project_roles](#refs-iam_project_roles))*
- **service_encryption_key_ids**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z-]+\.googleapis\.com$`**: *array*
    - items: *string*
- **services**: *array*
  - items: *string*
- **shared_vpc_host_config**: *object*
  <br>*no additional properties allowed*
  - ⁺**enabled**: *boolean*
  - **service_projects**: *array*
    - items: *string*
- **shared_vpc_service_config**: *object*
  <br>*no additional properties allowed*
  - ⁺**host_project**: *string*
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
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *string*
- **tags**: *object*
  *additional properties: Object*
- **vpc_sc**: *object*
  - ⁺**perimeter_name**: *string*
  - **perimeter_bridges**: *array*
    - items: *string*
  - **is_dry_run**: *boolean*

## Definitions

- **bucket**<a name="refs-bucket"></a>: *object*
  <br>*no additional properties allowed*
  - **description**: *string*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **labels**: *object*
    *additional properties: String*
  - **location**: *string*
  - **prefix**: *string*
  - **storage_class**: *string*
  - **uniform_bucket_level_access**: *boolean*
  - **versioning**: *boolean*
- **buckets**<a name="refs-buckets"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *reference([bucket](#refs-bucket))*
- **iam**<a name="refs-iam"></a>: *object*
  <br>*no additional properties allowed*
  - **`^roles/`**: *array*
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
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|[a-z])`**: *array*
    - items: *string*
- **iam_billing_roles**<a name="refs-iam_billing_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_folder_roles**<a name="refs-iam_folder_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_organization_roles**<a name="refs-iam_organization_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_project_roles**<a name="refs-iam_project_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_sa_roles**<a name="refs-iam_sa_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
# Project

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **automation**: *object*
  <br>*additional properties: false*
  - **prefix**: *string*
    <br>*pattern: None*
  - ⁺**project**: *string*
    <br>*pattern: None*
  - **bucket**: *reference([bucket](#refs-bucket))*
  - **service_accounts**: *object*
    <br>*additional properties: false*
    - **`^[a-z0-9-]+$`**: *object*
      <br>*additional properties: false*
      - **description**: *string*
        <br>*pattern: None*
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
  <br>*pattern: None*
- **billing_budgets**: *array*
  - items: *string*
    <br>*pattern: None*
- **buckets**: *reference([buckets](#refs-buckets))*
- **contacts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **deletion_policy**: *string*
  <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*, *pattern: None*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **labels**: *object*
- **metric_scopes**: *array*
  - items: *string*
    <br>*pattern: None*
- **name**: *string*
  <br>*pattern: None*
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
- **parent**: *string*
  <br>*pattern: None*
- **prefix**: *string*
  <br>*pattern: None*
- **project_reuse**: *object*
  <br>*additional properties: false*
  - **use_data_source**: *boolean*
  - **project_attributes**: *object*
    - ⁺**name**: *string*
      <br>*pattern: None*
    - ⁺**number**: *number*
    - **services_enabled**: *array*
      - items: *string*
        <br>*pattern: None*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **display_name**: *string*
      <br>*pattern: None*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_self_roles**: *array*
      - items: *string*
        <br>*pattern: None*
    - **iam_project_roles**: *reference([iam_project_roles](#refs-iam_project_roles))*
    - **iam_sa_roles**: *reference([iam_sa_roles](#refs-iam_sa_roles))*
- **service_encryption_key_ids**: *object*
  <br>*additional properties: false*
  - **`^[a-z-]+\.googleapis\.com$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **services**: *array*
  - items: *string*
    <br>*pattern: ^[a-z-]+\.googleapis\.com$*
- **shared_vpc_host_config**: *object*
  <br>*additional properties: false*
  - ⁺**enabled**: *boolean*
  - **service_projects**: *array*
    - items: *string*
      <br>*pattern: None*
- **shared_vpc_service_config**: *object*
  <br>*additional properties: false*
  - ⁺**host_project**: *string*
    <br>*pattern: None*
  - **network_users**: *array*
    - items: *string*
      <br>*pattern: None*
  - **service_agent_iam**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
        <br>*pattern: None*
  - **service_agent_subnet_iam**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
        <br>*pattern: None*
  - **service_iam_grants**: *array*
    - items: *string*
      <br>*pattern: None*
  - **network_subnet_users**: *object*
    - **`^[a-z0-9_-]+$`**: *array*
      - items: *string*
        <br>*pattern: None*
- **tag_bindings**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*
    <br>*pattern: None*
- **tags**: *object*
  *additional properties: Object*
- **vpc_sc**: *object*
  - ⁺**perimeter_name**: *string*
    <br>*pattern: None*
  - **perimeter_bridges**: *array*
    - items: *string*
      <br>*pattern: None*
  - **is_dry_run**: *boolean*

## Definitions

- **bucket**<a name="refs-bucket"></a>: *object*
  <br>*additional properties: false*
  - **description**: *string*
    <br>*pattern: None*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **labels**: *object*
    *additional properties: String*
  - **location**: *string*
    <br>*pattern: None*
  - **prefix**: *string*
    <br>*pattern: None*
  - **storage_class**: *string*
    <br>*pattern: None*
  - **uniform_bucket_level_access**: *boolean*
  - **versioning**: *boolean*
- **buckets**<a name="refs-buckets"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *reference([bucket](#refs-bucket))*
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
- **iam_billing_roles**<a name="refs-iam_billing_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **iam_folder_roles**<a name="refs-iam_folder_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **iam_organization_roles**<a name="refs-iam_organization_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **iam_project_roles**<a name="refs-iam_project_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **iam_sa_roles**<a name="refs-iam_sa_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
      <br>*pattern: None*

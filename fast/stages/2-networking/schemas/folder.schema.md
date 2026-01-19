# Folder

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
- **autokey_config**: *object*
  <br>*additional properties: false*
  - **project**: *string*
    <br>*pattern: ^(projects/|\$project_ids:|\$project_numbers:)*
- **billing_budgets**: *array*
  - items: *string*
- **contacts**: *object*
  <br>*additional properties: false*
  - **`^(\S+@\S+\.\S+|\$email_addresses:\S+)$`**: *array*
    - items: *string*
      <br>*enum: ['ALL', 'BILLING', 'LEGAL', 'SECURITY', 'PRODUCT_UPDATES', 'SUSPENSION', 'TECHNICAL']*
- **data_access_logs**: *object*
  <br>*additional properties: false*
  - **`^([a-z][a-z-]+\.googleapis\.com|allServices)$`**: *object*
    <br>*additional properties: false*
    - **ADMIN_READ**: *object*
      <br>*additional properties: false*
      - **exempted_members**: *array*
        - items: *string*
    - **DATA_READ**: *object*
      <br>*additional properties: false*
      - **exempted_members**: *array*
        - items: *string*
    - **DATA_WRITE**: *object*
      <br>*additional properties: false*
      - **exempted_members**: *array*
        - items: *string*
- **deletion_protection**: *boolean*
- **factories_config**: *object*
  <br>*additional properties: false*
  - **org_policies**: *string*
  - **pam_entitlements**: *string*
  - **scc_sha_custom_modules**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **iam_by_principals_conditional**: *reference([iam_by_principals_conditional](#refs-iam_by_principals_conditional))*
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
- **pam_entitlements**: *reference([pam_entitlements](#refs-pam_entitlements))*
- **parent**: *string*
  <br>*pattern: ^(?:folders/[0-9]+|organizations/[0-9]+|\$folder_ids:[a-z0-9_-]+)$*
- **tag_bindings**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*

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
    <br>*additional properties: string*
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
- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|\$custom_roles:)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:)*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:)*
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
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
- **iam_by_principals_conditional**<a name="refs-iam_by_principals_conditional"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:)`**: *object*
    <br>*additional properties: false*
    - ⁺**condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
    - ⁺**roles**: *array*
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
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_sa_roles**<a name="refs-iam_sa_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **iam_storage_roles**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **pam_entitlements**<a name="refs-pam_entitlements"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z][a-z0-9-]{0,61}[a-z0-9]$`**: *object*
    <br>*additional properties: false*
    - ⁺**max_request_duration**: *string*
    - ⁺**eligible_users**: *array*
      - items: *string*
    - ⁺**privileged_access**: *array*
      - items: *object*
        <br>*additional properties: false*
        - ⁺**role**: *string*
        - **condition**: *string*
    - **requester_justification_config**: *object*
      <br>*additional properties: false*
      - **not_mandatory**: *boolean*
      - **unstructured**: *boolean*
    - **manual_approvals**: *object*
      <br>*additional properties: false*
      - ⁺**require_approver_justification**: *boolean*
      - ⁺**steps**: *array*
        - items: *object*
          <br>*additional properties: false*
          - ⁺**approvers**: *array*
            - items: *string*
          - **approvals_needed**: *number*
          - **approver_email_recipients**: *array*
            - items: *string*
    - **additional_notification_targets**: *object*
      <br>*additional properties: false*
      - **admin_email_recipients**: *array*
        - items: *string*
      - **requester_email_recipients**: *array*
        - items: *string*

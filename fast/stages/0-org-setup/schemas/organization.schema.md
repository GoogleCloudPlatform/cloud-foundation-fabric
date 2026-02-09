# Organization

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **asset_feeds**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**billing_project**: *string*
    - **content_type**: *string*
      <br>*enum: ['RESOURCE', 'IAM_POLICY', 'ORG_POLICY', 'ACCESS_POLICY', 'OS_INVENTORY', 'RELATIONSHIP']*
    - **asset_types**: *array*
      - items: *string*
    - **asset_names**: *array*
      - items: *string*
    - ⁺**feed_output_config**: *object*
      <br>*additional properties: false*
      - ⁺**pubsub_destination**: *object*
        <br>*additional properties: false*
        - ⁺**topic**: *string*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - **title**: *string*
      - **description**: *string*
      - **location**: *string*
- **id**: *string*
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
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **iam_by_principals_conditional**: *reference([iam_by_principals_conditional](#refs-iam_by_principals_conditional))*
- **iam_by_principals_additive**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **logging**: *object*
  <br>*additional properties: false*
  - **kms_key_name**: *string*
  - **storage_location**: *string*
  - **sinks**: *object*
    <br>*additional properties: false*
    - **`^[a-z][a-z0-9-_]+$`**: *object*
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
- **pam_entitlements**: *reference([pam_entitlements](#refs-pam_entitlements))*
- **tags**: *object*
  <br>*additional properties: object*
- **workforce_identity_config**: *object*
  <br>*additional properties: false*
  - **pool_name**: *string*
  - **display_name**: *string*
  - **description**: *string*
  - **disabled**: *boolean*
  - **session_duration**: *string*
  - **access_restrictions**: *object*
    <br>*additional properties: false*
    - **allowed_services**: *array*
      - items: *object*
        <br>*additional properties: false*
        - **domain**: *string*
    - **disable_programmatic_signin**: *boolean*
  - **providers**: *object*
    <br>*additional properties: false*
    - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
      <br>*additional properties: false*
      - **description**: *string*
      - **display_name**: *string*
      - **attribute_condition**: *string*
      - **attribute_mapping**: *object*
      - **attribute_mapping_template**: *string*
        <br>*enum: ['azuread', 'okta']*
      - **disabled**: *boolean*
      - **identity_provider**: *object*
      - **oauth2_client_config**: *object*
        <br>*additional properties: false*
        - **extended_attributes**: *reference([wfif_oauth2_client_attrs](#refs-wfif_oauth2_client_attrs))*
        - **extra_attributes**: *reference([wfif_oauth2_client_attrs](#refs-wfif_oauth2_client_attrs))*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|$custom_roles:|organizations/|projects/)`**: *array*
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
      <br>*pattern: ^(?:roles/|\$custom_roles:)*
- **iam_by_principals_conditional**<a name="refs-iam_by_principals_conditional"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:\$[a-z_-]+:|domain:|group:|serviceAccount:|user:|principal:|principalSet:)`**: *object*
    <br>*additional properties: false*
    - ⁺**condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
    - ⁺**roles**: *array*
      - items: *string*
        <br>*pattern: ^(?:roles/|\$custom_roles:)*
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
- **wfif_oauth2_client_attrs**<a name="refs-wfif_oauth2_client_attrs"></a>: *object*
  <br>*additional properties: false*
  - ⁺**issuer_uri**: *string*
  - ⁺**client_id**: *string*
  - ⁺**client_secret**: *string*
  - **attributes_type**: *string*
    <br>*enum: ['AZURE_AD_GROUPS_MAIL', 'AZURE_AD_GROUPS_ID']*
  - **query_filter**: *string*

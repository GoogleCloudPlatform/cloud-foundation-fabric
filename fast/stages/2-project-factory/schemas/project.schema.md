# Project

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **asset_feeds**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **billing_project**: *string*
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
      - **prefix**: *string*
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
- **datasets**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_]+$`**: *object*
    <br>*additional properties: false*
    - **friendly_name**: *string*
    - **location**: *string*
    - **encryption_key**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
    - **options**: *object*
      <br>*additional properties: false*
      - **default_table_expiration_ms**: *number*
      - **default_partition_expiration_ms**: *number*
      - **delete_contents_on_destroy**: *boolean*
      - **max_time_travel_hours**: *number*
    - **tag_bindings**: *reference([tag_bindings](#refs-tag_bindings))*
- **deletion_policy**: *string*
  <br>*enum: ['PREVENT', 'DELETE', 'ABANDON']*
- **factories_config**: *object*
  <br>*additional properties: false*
  - **custom_roles**: *string*
  - **observability**: *string*
  - **org_policies**: *string*
  - **quotas**: *string*
  - **scc_sha_custom_modules**: *string*
  - **tags**: *string*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **iam_by_principals_conditional**: *reference([iam_by_principals_conditional](#refs-iam_by_principals_conditional))*
- **iam_by_principals_additive**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **kms**: *object*
  <br>*additional properties: false*
  - **autokeys**: *object*
    <br>*additional properties: false*
    - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
      <br>*additional properties: false*
      - ⁺**location**: *string*
      - ⁺**resource_type_selector**: *string*
  - **keyrings**: *object*
    <br>*additional properties: false*
    - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
      <br>*additional properties: false*
      - ⁺**location**: *string*
      - **iam**: *reference([iam](#refs-iam))*
      - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
      - **tag_bindings**: *reference([tag_bindings](#refs-tag_bindings))*
      - **keys**: *object*
        <br>*additional properties: false*
        - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
          <br>*additional properties: false*
          - **destroy_scheduled_duration**: *string*
          - **rotation_period**: *string*
          - **iam**: *reference([iam](#refs-iam))*
          - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
          - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
          - **purpose**: *string*
            <br>*default: ENCRYPT_DECRYPT*, *enum: ['CRYPTO_KEY_PURPOSE_UNSPECIFIED', 'ENCRYPT_DECRYPT', 'ASYMMETRIC_SIGN', 'ASYMMETRIC_DECRYPT', 'RAW_ENCRYPT_DECRYPT', 'MAC']*
          - **version_template**: *object*
            <br>*additional properties: false*
            - ⁺**algorithm**: *string*
            - **protection_level**: *string*
              <br>*default: SOFTWARE*, *enum: ['SOFTWARE', 'HSM', 'EXTERNAL', 'EXTERNAL_VPC']*
- **labels**: *object*
- **pam_entitlements**: *reference([pam_entitlements](#refs-pam_entitlements))*
- **log_buckets**: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9_-]+$`**: *reference([log_bucket](#refs-log_bucket))*
- **metric_scopes**: *array*
  - items: *string*
- **name**: *string*
- **descriptive_name**: *string*
- **dns_threat_detector**: *object*
  <br>*additional properties: false*
  - **enabled**: *boolean*
  - **excluded_networks**: *array*
    - items: *string*
  - **labels**: *object*
  - **location**: *string*
  - **name**: *string*
  - **threat_detector_provider**: *string*
    <br>*enum: ['INFOBLOX']*
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
      <br>*additional properties: string*
    - **justification**: *string*
    - **contact_email**: *string*
    - **annotations**: *object*
      <br>*additional properties: string*
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
- **project_template**: *string*
- **pubsub_topics**: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9_-]+$`**: *reference([pubsub_topic](#refs-pubsub_topic))*
- **service_accounts**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **display_name**: *string*
    - **iam**: *reference([iam](#refs-iam))*
    - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
    - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
    - **iam_self_roles**: *array*
      - items: *string*
    - **iam_project_roles**: *reference([iam_project_roles](#refs-iam_project_roles))*
    - **iam_sa_roles**: *reference([iam_sa_roles](#refs-iam_sa_roles))*
    - **tag_bindings**: *reference([tag_bindings](#refs-tag_bindings))*
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
- **tags**: *object*
  <br>*additional properties: object*
- **tag_bindings**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*
- **universe**: *object*
  <br>*additional properties: false*
  - **prefix**: *string*
  - **forced_jit_service_identities**: *array*
    - items: *string*
  - **unavailable_services**: *array*
    - items: *string*
  - **unavailable_service_identities**: *array*
    - items: *string*
- **vpc_sc**: *object*
  - ⁺**perimeter_name**: *string*
  - **is_dry_run**: *boolean*
- **workload_identity_pools**: *object*
  <br>*additional properties: false*
  - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
    <br>*additional properties: false*
    - **description**: *string*
    - **display_name**: *string*
    - **disabled**: *boolean*
    - **providers**: *object*
      <br>*additional properties: false*
      - **`^[a-z][a-z0-9-]+[a-z0-9]$`**: *object*
        <br>*additional properties: false*
        - **description**: *string*
        - **display_name**: *string*
        - **disabled**: *boolean*
        - **attribute_condition**: *string*
        - **attribute_mapping**: *object*
          <br>*additional properties: string*
        - **identity_provider**: *object*

## Definitions

- **bucket**<a name="refs-bucket"></a>: *object*
  <br>*additional properties: false*
  - **name**: *string*
  - **create**: *boolean*
  - **description**: *string*
  - **encryption_key**: *string*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **force_destroy**: *boolean*
  - **labels**: *object*
    <br>*additional properties: string*
  - **lifecycle_rules**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9_-]+$`**: *object*
      <br>*additional properties: false*
      - ⁺**action**: *object*
        <br>*additional properties: false*
        - ⁺**type**: *string*
          <br>*enum: ['Delete', 'SetStorageClass', 'AbortIncompleteMultipartUpload']*
        - **storage_class**: *string*
      - ⁺**condition**: *object*
        <br>*additional properties: false*
        - **age**: *number*
        - **created_before**: *string*
        - **custom_time_before**: *string*
        - **days_since_custom_time**: *number*
        - **days_since_noncurrent_time**: *number*
        - **matches_prefix**: *array*
          - items: *string*
        - **matches_storage_class**: *array*
          - items: *string*
            <br>*enum: ['STANDARD', 'MULTI_REGIONAL', 'REGIONAL', 'NEARLINE', 'COLDLINE', 'ARCHIVE', 'DURABLE_REDUCED_AVAILABILITY']*
        - **matches_suffix**: *array*
          - items: *string*
        - **noncurrent_time_before**: *string*
        - **num_newer_versions**: *number*
        - **with_state**: *string*
          <br>*enum: ['LIVE', 'ARCHIVED', 'ANY']*
  - **logging_config**: *object*
    <br>*additional properties: false*
    - ⁺**log_bucket**: *string*
    - **log_object_prefix**: *string*
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
  - **retention_policy**: *object*
    <br>*additional properties: false*
    - **retention_period**: *string*
    - **is_locked**: *boolean*
  - **soft_delete_retention**: *number*
  - **enable_object_retention**: *boolean*
  - **tag_bindings**: *reference([tag_bindings](#refs-tag_bindings))*
  - **custom_placement_config**: *array*
    - items: *string*
- **buckets**<a name="refs-buckets"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *reference([bucket](#refs-bucket))*
- **[iam](#refs-iam_ex)**<a name="refs-iam"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:||\$iam_principals:[a-z0-9_-]+)*
- **[iam_bindings](#refs-iam_bindings_ex)**<a name="refs-iam_bindingse"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **members**: *array*
      - items: *string*
        <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **[iam_bindings_additive](#refs-iam_additive_ex)**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **member**: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
    - **role**: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
    - **condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
- **[iam_by_principals](#refs-iam_by_principals_ex)**: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)`**: *array*
    - items: *string*
      <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
- **[iam_by_principals_conditional](#refs-iam_by_principals_conditional_ex)**<a name="refs-iam_by_principals_conditional"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)`**: *object*
    <br>*additional properties: false*
    - ⁺**condition**: *object*
      <br>*additional properties: false*
      - ⁺**expression**: *string*
      - ⁺**title**: *string*
      - **description**: *string*
    - ⁺**roles**: *array*
      - items: *string*
        <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
- **[iam_billing_roles](#refs-iam_billing_roles_ex)**<a name="refs-iam_billing_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **[iam_folder_roles](#refs-iam_folder_roles_ex)**<a name="refs-iam_folder_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **[iam_organization_roles](#refs-iam_organization_roles_ex)**<a name="refs-iam_organization_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **[iam_project_roles](#refs-iam_project_roles_ex)**<a name="refs-iam_project_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^(?:[a-z0-9-]|\$project_ids:[a-z0-9_-])+$`**: *array*
    - items: *string*
- **[iam_sa_roles](#refs-iam_sa_roles_ex)**<a name="refs-iam_sa_roles"></a>: *object* 
  <br>* Used to manage permissions for Service Accounts. This allows you to define who can "act as" a service account or manage the service account's own keys and identity. *</br>
  <br>*additional properties: false*
  - **`^(?:\$service_account_ids:|projects/)`**: *array*
    - items: *string*
- **[iam_storage_roles](#refs-iam_storage_roles_ex)**<a name="refs-iam_storage_roles"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *array*
    - items: *string*
- **[log_bucket](#refs-log_buckets_ex)**<a name="refs-log_bucket"></a>: *object*
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
- **[pam_entitlements](#refs-pam_entitlements_ex)**<a name="refs-pam_entitlements"></a>: *object*
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
- **pubsub_topic**<a name="refs-pubsub_topic"></a>: *object*
  <br>*additional properties: false*
  - **iam**: *reference([iam](#refs-iam))*
  - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
  - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
  - **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
  - **kms_key**: *string*
  - **labels**: *object*
    <br>*additional properties: string*
  - **message_retention_duration**: *string*
  - **regions**: *array*
    - items: *string*
  - **schema**: *object*
    <br>*additional properties: false*
    - ⁺**definition**: *string*
    - **msg_encoding**: *string*
    - ⁺**schema_type**: *string*
  - **subscriptions**: *object*
    <br>*additional properties: false*
    - **`^[a-zA-Z0-9_-]+$`**: *object*
      <br>*additional properties: false*
      - **ack_deadline_seconds**: *number*
      - **enable_exactly_once_delivery**: *boolean*
      - **enable_message_ordering**: *boolean*
      - **expiration_policy_ttl**: *string*
      - **filter**: *string*
      - **iam**: *reference([iam](#refs-iam))*
      - **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
      - **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
      - **labels**: *object*
        <br>*additional properties: string*
      - **message_retention_duration**: *string*
      - **retain_acked_messages**: *boolean*
      - **bigquery**: *object*
        <br>*additional properties: false*
        - ⁺**table**: *string*
        - **drop_unknown_fields**: *boolean*
        - **service_account_email**: *string*
        - **use_table_schema**: *boolean*
        - **use_topic_schema**: *oolean*
        - **write_metadata**: *boolean*
      - **cloud_storage**: *object*
        <br>*additional properties: false*
        - ⁺**bucket**: *string*
        - **filename_prefix**: *string*
        - **filename_suffix**: *string*
        - **max_duration**: *string*
        - **max_bytes**: *number*
        - **avro_config**: *object*
          <br>*additional properties: false*
          - **write_metadata**: *boolean*
      - **dead_letter_policy**: *object*
        <br>*additional properties: false*
        - ⁺**topic**: *string*
        - **max_delivery_attempts**: *number*
      - **push**: *object*
        <br>*additional properties: false*
        - ⁺**endpoint**: *string*
        - **attributes**: *object*
          <br>*additional properties: string*
        - **no_wrapper**: *object*
          <br>*additional properties: false*
          - **write_metadata**: *boolean*
        - **oidc_token**: *object*
          <br>*additional properties: false*
          - **audience**: *string*
          - ⁺**service_account_email**: *string*
      - **retry_policy**: *object*
        <br>*additional properties: false*
        - **minimum_backoff**: *number*
        - **maximum_backoff**: *number*
- **tag_bindings**<a name="refs-tag_bindings"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *string*

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_billing_account_iam_member</code> · <code>google_folder_iam_member</code> · <code>google_organization_iam_member</code> · <code>google_project_iam_member</code> · <code>google_service_account_iam_binding</code> · <code>google_service_account_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_service_account</code> · <code>google_tags_tag_binding</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | descriptios  | scope & inpact | example | scenario |
|---|-----|:---:|:---:|:---:|
|**name** | The unique, permanent ID for the project  | Global: Identifies your project across Google Cloud. | "finance-prod-app-01" | Identifying a specific "account" for technical support or billing|
| **descriptive_name** | A friendly, readable name for human identification. | Metadata: Purely for display in the console. | "Production Payment Gateway" | A manager looking at a list and seeing a clear name instead of a code.|
| **parent** | The ID of the Folder or Org that owns this project. | Org Hierarchy: Defines ownership and inheritance. | "folders/123456789" | Placing an "HR Project" in the "Internal Tools" folder.|
|**billing_account** | The financial account linked to pay for usage. | Financial: If invalid, services will stop. | "01A2B3-XYZ987" | Assigning a corporate credit card to a specific research project.|
|**services** | List of specific Google features to activate. | Feature Level: Turns on specific tools/utilities. | ["compute.googleapis.com"] | Turning on the "Electricity" (Power) so you can run servers.|
|**iam** | iam: Defines authoritative role assignments (meaning it overwrites existing ones) for users, groups, or service accounts at the current resource level. reference(iam). | Project-Wide: High-level security control. <a name="refs-iam_ex"></a>| {"roles/owner": ["user:admin@co.com"]} | A new Director taking over and issuing a brand new access list.|
|**iam_bindings**  |iam_billing_roles: Assigns IAM roles specifically to manage or view the GCP Billing Account. reference(iam_billing_roles). <a name="refs-iam_bindings_ex"></a> | {"dev-group": ["roles/viewer"]} reference([iam_bindings](#refs-iam_bindingse)) | Giving the "Accounting Team" a keycard for the "Records" room.|
|**iam_bindings_additive** | iam_bindings_additive: Safely appends new IAM permissions without deleting or overwriting existing bindings (ideal for shared resources). reference(iam_bindings_additive)| Individual Level: Precise access for one person. | {"consultant": ["roles/editor"]} <a name="refs-iam_additive_ex"></a>| Giving a temporary visitor pass to a specific contractor.|
|**service_accounts**  | Identities used by software for automated tasks. | Functional: For apps rather  than humans.<a name="refs-service_account_ex"></a> | "cleanup-bot@project.iam.gserviceaccount.com" | An automated robot that copies files to backup every night.|
|**iam_folder_roles** |iam_folder_roles: Grants IAM roles that automatically cascade down to all projects within a specific Folder. reference(iam_folder_roles)|<a name="refs-iam_folder_roles_ex"></a>. Hierarchy Level: Multi-project inherited access. | {"folder/123": ["roles/viewer"]} |
|**iam_organization_roles** |iam_organization_roles: Grants top-level, broad IAM roles that apply globally across the entire Organization. reference(iam_organization_roles)|<a name="refs-iam_organization_roles_ex"></a> Global Level: Broadest possible access scope. | {"org/456": ["roles/resourcemanager.organizationViewer"]} |
|**iam_project_roles** |iam_project_roles: Assigns IAM roles scoped exclusively to a specific Google Cloud Project. reference(iam_project_roles)|<a name="refs-iam_project_roles_ex"></a>.  Project Level: Standard scoped access. | {"my-dev-project": ["roles/editor"]} |
|**iam_sa_roles** |iam_sa_roles: Grants permissions on a Service Account (e.g., allowing a user or group to impersonate that specific service account). reference(iam_sa_roles)|<a name="refs-iam_sa_roles_ex"></a> Identity Level: Service account impersonation. | {"venafi-sa@...": ["roles/iam.serviceAccountUser"]} |
|**iam_storage_roles**|iam_storage_roles: Assigns IAM roles specifically for accessing, managing, or viewing Cloud Storage buckets.<a name="refs-iam_storage_roles_ex"></a>| Resource Level: Targeted data access. | {"backup-bucket": ["roles/storage.objectViewer"]} |
| **buckets** | buckets: Digital storage folders used to hold files, backups, and large data objects securely. | Resource Level: Storage units in the project. | {"app-backups": {"location": "EU"}} |
| **pubsub_topics** | pubsub_topics: A messaging hub that allows different applications to talk to each other by sending and receiving notifications. | Resource Level: Internal communication hub. | {"order-notifications": {}} |
| **kms** | kms: A centralized system that manages the digital keys used to lock (encrypt) and unlock (decrypt) your sensitive data. | Data Privacy: Locks the actual information. | "projects/p1/locations/us/keyRings/r1" |
| **org_policies** | org_policies: Hard security rules set at the company level to prevent risky actions (like making a database public). | Compliance: Governs forbidden actions. | {"iam.disableServiceAccountKeyCreation": {}} |
| **quotas** | quotas: Usage limits that prevent any single service from overspending or consuming too many cloud resources. | Resource Guardrail: Controls costs/usage. | {"service": "compute", "limit": 10} |
| **log_buckets** | log_buckets: Specialized, tamper-proof containers used specifically to store history of who did what and when. | Audit Trail: Used for security reviews.<a name="refs-log_buckets_ex"></a> | {"audit-logs": {"retention": 90}} |
| **labels** | labels: Descriptive tags used to organize and filter your resources for easier billing and inventory tracking. | Metadata: Helps Finance sort costs. | {"department": "marketing"} |
| **contacts** | contacts: A list of verified email addresses that Google will notify if there is a security or technical emergency. | Human Layer: Who to call for outages. | {"admin-group": ["TECHNICAL"]} |
| **vpc_sc** | vpc_sc: A virtual security wall that prevents data from being accidentally or intentionally moved outside your network. | Network Security: Data theft protection. | {"perimeter_name": "it_secure_zone"} |
| **deletion_policy** | deletion_policy: A "safety lock" that determines if a project is allowed to be deleted or if it is protected from removal. | Safety Lock: Prevents accidental loss. | "PREVENT" |
| **pam_entitlements** | pam_entitlements: Grants temporary, elevated permissions that expire automatically to keep the project secure.<a name="refs-pam_entitlements_ex"></a> | Just-in-Time: Access that expires quickly. | "admin-access": ["roles/resourcemanager.admin"] |
| **datasets** | datasets: Organized containers in BigQuery used to hold and manage your structured tables and database info. | Data Level: Where business data lives. | {"sales_data_2023": {"location": "US"}} |
| **automation** | automation: Configuration settings for the automated tools that deploy and manage your cloud infrastructure. | Management: Control Layer. | {"terraform_version": "1.5.0"} |
| **iam_by_principle** | iam_by_principle: Assigns multiple IAM roles to a specific user, group, or service account across the project in a single configuration. | Identity Level: Consolidated permissions for one principal. <a name="refs-iam_by_principals_ex"></a> | {"user:admin@company.com": ["roles/viewer", "roles/editor"]} |
| **iam_by_principals_conditional** | iam_by_principals_conditional: Assigns IAM roles to principals only when specific conditions are met (e.g., restricted by time, date, or resource name). | Identity Level: Logic-based access control.<a name="refs-iam_by_principals_conditional_ex"></a> | {"user:dev@company.com": {"roles": ["roles/editor"], "condition": {"title": "expires_after_2025", "expression": "request.time < timestamp('2025-01-01T00:00:00Z')"}}} |
## Outputs

| Name | Description | Sensitive |
|---|-------|:---:|
| [email](outputs.tf#L17) | Service account email. |  |
| [iam_email](outputs.tf#L25) | IAM-format service account email. |  |
| [id](outputs.tf#L33) | Fully qualified service account id. |  |
| [name](outputs.tf#L41) | Service account name. |  |
| [service_account](outputs.tf#L49) | Service account resource. |  |
| [unique_id](outputs.tf#L54) | Fully qualified service account id. |  |
<!-- END TFDOC -->

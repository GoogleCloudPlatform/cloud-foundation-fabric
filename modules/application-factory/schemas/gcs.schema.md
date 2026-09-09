# GCS Bucket

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **autoclass**: *boolean*
- **cors**: *object*
  <br>*additional properties: false*
  - **origin**: *array*
    - items: *string*
  - **method**: *array*
    - items: *string*
  - **response_header**: *array*
    - items: *string*
  - **max_age_seconds**: *number*
- **custom_placement_config**: *array*
  - items: *string*
- **default_event_based_hold**: *boolean*
- **enable_hierarchical_namespace**: *boolean*
- **enable_object_retention**: *boolean*
- **encryption_key**: *string*
- **force_destroy**: *boolean*
- **iam**: *reference([iam](#refs-iam))*
- **iam_bindings**: *reference([iam_bindings](#refs-iam_bindings))*
- **iam_bindings_additive**: *reference([iam_bindings_additive](#refs-iam_bindings_additive))*
- **iam_by_principals**: *reference([iam_by_principals](#refs-iam_by_principals))*
- **ip_filter**: *object*
  <br>*additional properties: false*
  - **allow_cross_org_vpcs**: *boolean*
  - **allow_all_service_agent_access**: *boolean*
  - **public_network_sources**: *array*
    - items: *string*
  - **vpc_network_sources**: *object*
    <br>*additional properties: array*
- **kms_autokeys**: *object*
  <br>*additional properties: object*
- **labels**: *object*
  <br>*additional properties: string*
- **lifecycle_rules**: *object*
  <br>*additional properties: object*
- **location**: *string*
- **logging_config**: *object*
  <br>*additional properties: false*
  - ⁺**log_bucket**: *string*
  - **log_object_prefix**: *string*
- **managed_folders**: *object*
  <br>*additional properties: object*
- **name**: *string*
- **notification_config**: *object*
  <br>*additional properties: false*
  - ⁺**enabled**: *boolean*
  - ⁺**payload_format**: *string*
  - ⁺**sa_email**: *string*
  - ⁺**topic_name**: *string*
  - **create_topic**: *object*
    <br>*additional properties: false*
    - **create**: *boolean*
    - **kms_key_id**: *string*
  - **event_types**: *array*
    - items: *string*
  - **custom_attributes**: *object*
    <br>*additional properties: string*
  - **object_name_prefix**: *string*
- **objects_to_upload**: *object*
  <br>*additional properties: object*
- **prefix**: *string*
- **project_id**: *string*
- **public_access_prevention**: *string*
  <br>*enum: ['enforced', 'inherited']*
- **requester_pays**: *boolean*
- **retention_policy**: *object*
  <br>*additional properties: false*
  - ⁺**retention_period**: *string*
  - **is_locked**: *boolean*
- **rpo**: *string*
- **soft_delete_retention**: *number*
- **storage_class**: *string*
  <br>*enum: ['STANDARD', 'MULTI_REGIONAL', 'REGIONAL', 'NEARLINE', 'COLDLINE', 'ARCHIVE']*
- **tag_bindings**: *object*
  <br>*additional properties: string*
- **uniform_bucket_level_access**: *boolean*
- **versioning**: *boolean*
- **website**: *object*
  <br>*additional properties: false*
  - **main_page_suffix**: *string*
  - **not_found_page**: *string*

## Definitions

- **iam**<a name="refs-iam"></a>: *object*
  <br>*additional properties: array*
- **iam_bindings**<a name="refs-iam_bindings"></a>: *object*
  <br>*additional properties: object*
- **iam_bindings_additive**<a name="refs-iam_bindings_additive"></a>: *object*
  <br>*additional properties: object*
- **iam_by_principals**<a name="refs-iam_by_principals"></a>: *object*
  <br>*additional properties: array*

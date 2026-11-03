# Security Policy

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **name**: *string*
- ⁺**parent_id**: *object*
  <br>*additional properties: false*
  - **organization_id**: *string*
  - **folder_id**: *string*
- **attachments**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**id**: *string*
    - **excluded_folders**: *array*
      - items: *string*
    - **excluded_projects**: *array*
      - items: *string*
- **advanced_options_config**: *object*
  <br>*additional properties: false*
  - **json_parsing**: *string*
    <br>*enum: ['DISABLED', 'STANDARD', 'STANDARD_WITH_GRAPHQL']*
  - **log_level**: *string*
    <br>*enum: ['NORMAL', 'VERBOSE']*
  - **request_body_inspection_size**: *string*
    <br>*enum: ['8KB', '16KB', '32KB', '48KB', '64KB']*
  - **user_ip_request_headers**: *array*
    - items: *string*
  - **json_custom_content_types**: *array*
    - items: *string*
- **rules**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**priority**: *integer*
  - ⁺**action**: *string*
    <br>*pattern: ^(allow|deny|deny\((403|404|502)\)|goto_next|redirect)$*
  - **description**: *string*
  - **preview**: *boolean*
  - **match**: *object*
    <br>*additional properties: false*
    - **src_ip_ranges**: *array*
      - items: *string*
    - **expression**: *string*
  - **header_action**: *object*
    <br>*additional properties: string*
  - **preconfigured_waf_config**: *object*
    <br>*additional properties: false*
    - ⁺**exclusions**: *array*
      - items: *reference([waf_exclusion](#refs-waf_exclusion))*
  - **redirect_options**: *reference([redirect_options](#refs-redirect_options))*
- **waf_exclusion**<a name="refs-waf_exclusion"></a>: *object*
  <br>*additional properties: false*
  - ⁺**target_rule_set**: *string*
  - **target_rule_ids**: *array*
    - items: *string*
  - **request_cookies**: *array*
    - items: *reference([waf_field_param](#refs-waf_field_param))*
  - **request_headers**: *array*
    - items: *reference([waf_field_param](#refs-waf_field_param))*
  - **request_query_params**: *array*
    - items: *reference([waf_field_param](#refs-waf_field_param))*
  - **request_uris**: *array*
    - items: *reference([waf_field_param](#refs-waf_field_param))*
- **waf_field_param**<a name="refs-waf_field_param"></a>: *object*
  <br>*additional properties: false*
  - ⁺**operator**: *string*
    <br>*enum: ['EQUALS', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS', 'EQUALS_ANY']*
  - **value**: *string*
- **redirect_options**<a name="refs-redirect_options"></a>: *object*
  <br>*additional properties: false*
  - ⁺**type**: *string*
    <br>*enum: ['EXTERNAL_302']*
  - **target**: *string*

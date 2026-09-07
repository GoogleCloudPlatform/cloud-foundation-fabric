# Cloud Armor Rules

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**priority**: *integer*
  - ⁺**action**: *string*
    <br>*pattern: ^(allow|deny|deny\((403|404|502)\)|throttle|rate_based_ban|redirect)$*
  - **description**: *string*
  - **preview**: *boolean*
  - **match**: *object*
    <br>*additional properties: false*
    - **src_ip_ranges**: *array*
      - items: *string*
    - **expression**: *string*
    - **recaptcha_options**: *object*
      <br>*additional properties: false*
      - **action_token_site_keys**: *array*
        - items: *string*
      - **session_token_site_keys**: *array*
        - items: *string*
  - **network_match**: *object*
    <br>*additional properties: false*
    - **dest_ip_ranges**: *array*
      - items: *string*
    - **dest_ports**: *array*
      - items: *string*
    - **ip_protocols**: *array*
      - items: *string*
    - **src_asns**: *array*
      - items: *integer*
    - **src_ip_ranges**: *array*
      - items: *string*
    - **src_ports**: *array*
      - items: *string*
    - **src_region_codes**: *array*
      - items: *string*
    - **user_defined_fields**: *object*
      <br>*additional properties: array*
  - **header_action**: *object*
    <br>*additional properties: string*
  - **preconfigured_waf_config**: *object*
    <br>*additional properties: false*
    - ⁺**exclusions**: *array*
      - items: *reference([waf_exclusion](#refs-waf_exclusion))*
  - **rate_limit_options**: *object*
    <br>*additional properties: false*
    - ⁺**exceed_action**: *string*
    - **rate_limit_threshold**: *reference([threshold](#refs-threshold))*
    - **ban_duration_sec**: *integer*
    - **ban_threshold**: *reference([threshold](#refs-threshold))*
    - **enforce_on_key**: *string*
      <br>*enum: ['ALL', 'IP', 'HTTP_HEADER', 'XFF_IP', 'HTTP_COOKIE', 'HTTP_PATH', 'SNI', 'REGION_CODE', 'TLS_JA3_FINGERPRINT', 'TLS_JA4_FINGERPRINT', 'USER_IP']*
    - **enforce_on_key_name**: *string*
    - **enforce_on_key_configs**: *array*
      - items: *object*
        <br>*additional properties: false*
        - ⁺**type**: *string*
        - **name**: *string*
    - **exceed_redirect_options**: *reference([redirect_options](#refs-redirect_options))*
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
- **threshold**<a name="refs-threshold"></a>: *object*
  <br>*additional properties: false*
  - ⁺**count**: *integer*
  - ⁺**interval_sec**: *integer*
- **redirect_options**<a name="refs-redirect_options"></a>: *object*
  <br>*additional properties: false*
  - ⁺**type**: *string*
    <br>*enum: ['GOOGLE_RECAPTCHA', 'EXTERNAL_302']*
  - **target**: *string*

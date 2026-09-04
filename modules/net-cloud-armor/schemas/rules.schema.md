# Cloud Armor Rules

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z0-9_-]+$`**: *reference([rule](#refs-rule))*

## Definitions

- **rule**<a name="refs-rule"></a>: *object*
  <br>*additional properties: false*
  - ⁺**priority**: *number*
  - ⁺**action**: *string*
    <br>*enum: ['allow', 'deny(403)', 'deny(404)', 'deny(502)', 'throttle', 'rate_based_ban', 'redirect']*
  - **description**: *string*
  - **preview**: *boolean*
  - **preconfigured_waf**: *string*
  - **threat_intel_feed**: *string*
  - **expression**: *string*
  - **src_ip_ranges**: *array*
    - items: *string*
  - **header_action**: *array*
    - items: *reference([header_action](#refs-header_action))*
  - **rate_limit_options**: *reference([rate_limit_options](#refs-rate_limit_options))*
  - **redirect_options**: *reference([redirect_options](#refs-redirect_options))*
- **header_action**<a name="refs-header_action"></a>: *object*
  <br>*additional properties: false*
  - ⁺**header_name**: *string*
  - ⁺**header_value**: *string*
- **rate_limit_options**<a name="refs-rate_limit_options"></a>: *object*
  <br>*additional properties: false*
  - **conform_action**: *string*
  - ⁺**exceed_action**: *string*
  - **enforce_on_key**: *string*
  - **enforce_on_key_name**: *string*
  - **ban_duration_sec**: *number*
  - **rate_limit_threshold**: *reference([threshold](#refs-threshold))*
  - **ban_threshold**: *reference([threshold](#refs-threshold))*
- **threshold**<a name="refs-threshold"></a>: *object*
  <br>*additional properties: false*
  - ⁺**count**: *number*
  - ⁺**interval_sec**: *number*
- **redirect_options**<a name="refs-redirect_options"></a>: *object*
  <br>*additional properties: false*
  - ⁺**type**: *string*
    <br>*enum: ['GOOGLE_RECAPTCHA', 'EXTERNAL_302']*
  - **target**: *string*

# Budget

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**amount**: *object*
  <br>*additional properties: false*
  - **currency_code**: *string*
    <br>*pattern: None*
  - **nanos**: *number*
  - **units**: *number*
  - **use_last_period**: *boolean*
- **display_name**: *string*
  <br>*pattern: None*
- **filter**: *object*
  <br>*additional properties: false*
  - **credit_types_treatment**: *object*
    <br>*additional properties: false*
    - **exclude_all**: *boolean*
    - **include_specified**: *array*
      - items: *string*
        <br>*pattern: None*
  - **label**: *object*
    <br>*additional properties: false*
    - **key**: *string*
      <br>*pattern: None*
    - **value**: *string*
      <br>*pattern: None*
  - **period**: *object*
    <br>*additional properties: false*
    - **calendar**: *string*
      <br>*pattern: None*
    - **custom**: *object*
      <br>*additional properties: false*
      - **start_date**: *reference([date](#refs-date))*
      - **end_date**: *reference([date](#refs-date))*
  - **projects**: *array*
    - items: *string*
      <br>*pattern: None*
  - **resource_ancestors**: *array*
    - items: *string*
      <br>*pattern: None*
  - **services**: *array*
    - items: *string*
      <br>*pattern: None*
  - **subaccounts**: *array*
    - items: *string*
      <br>*pattern: None*
- **threshold_rules**: *array*
  - items: *object*
    <br>*additional properties: false*
    - ⁺**percent**: *number*
    - **forecasted_spend**: *boolean*
- **update_rules**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*additional properties: false*
    - **disable_default_iam_recipients**: *boolean*
    - **monitoring_notification_channels**: *array*
      - items: *string*
        <br>*pattern: None*
    - **pubsub_topic**: *string*
      <br>*pattern: None*

## Definitions

- **date**<a name="refs-date"></a>: *object*
  <br>*additional properties: false*
  - **day**: *number*
  - **month**: *number*
  - **year**: *number*

# Budget

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**amount**: *object*
  <br>*additional properties: false*
  - **currency_code**: *string*
  - **nanos**: *number*
  - **units**: *number*
  - **use_last_period**: *boolean*
- **display_name**: *string*
- **filter**: *object*
  <br>*additional properties: false*
  - **credit_types_treatment**: *object*
    <br>*additional properties: false*
    - **exclude_all**: *boolean*
    - **include_specified**: *array*
      - items: *string*
  - **label**: *object*
    <br>*additional properties: false*
    - **key**: *string*
    - **value**: *string*
  - **period**: *object*
    <br>*additional properties: false*
    - **calendar**: *string*
    - **custom**: *object*
      <br>*additional properties: false*
      - **start_date**: *reference([date](#refs-date))*
      - **end_date**: *reference([date](#refs-date))*
  - **projects**: *array*
    - items: *string*
  - **resource_ancestors**: *array*
    - items: *string*
  - **services**: *array*
    - items: *string*
  - **subaccounts**: *array*
    - items: *string*
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
    - **pubsub_topic**: *string*

## Definitions

- **date**<a name="refs-date"></a>: *object*
  <br>*additional properties: false*
  - **day**: *number*
  - **month**: *number*
  - **year**: *number*

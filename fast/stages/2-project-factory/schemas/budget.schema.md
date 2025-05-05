# Budget

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- ⁺**amount**: *object*
  <br>*no additional properties allowed*
  - **currency_code**: *string*
  - **nanos**: *number*
  - **units**: *number*
  - **use_last_period**: *boolean*
- **display_name**: *string*
- **filter**: *object*
  <br>*no additional properties allowed*
  - **credit_types_treatment**: *object*
    <br>*no additional properties allowed*
    - **exclude_all**: *boolean*
    - **include_specified**: *array*
      - items: *string*
  - **label**: *object*
    <br>*no additional properties allowed*
    - **key**: *string*
    - **value**: *string*
  - **period**: *object*
    <br>*no additional properties allowed*
    - **calendar**: *string*
    - **custom**: *object*
      <br>*no additional properties allowed*
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
    <br>*no additional properties allowed*
    - ⁺**percent**: *number*
    - **forecasted_spend**: *boolean*
- **update_rules**: *object*
  <br>*no additional properties allowed*
  - **`^[a-z0-9_-]+$`**: *object*
    <br>*no additional properties allowed*
    - **disable_default_iam_recipients**: *boolean*
    - **monitoring_notification_channels**: *array*
      - items: *string*
    - **pubsub_topic**: *string*

## Definitions

- **date**<a name="refs-date"></a>: *object*
  <br>*no additional properties allowed*
  - **day**: *number*
  - **month**: *number*
  - **year**: *number*
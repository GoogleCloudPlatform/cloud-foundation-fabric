# Observability Schema

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **alerts**: *reference([alerts](#refs-alerts))*
- **logging_metrics**: *reference([logging_metrics](#refs-logging_metrics))*
- **notification_channels**: *reference([notification_channels](#refs-notification_channels))*

## Definitions

- **alerts**<a name="refs-alerts"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**combiner**: *string*
    - **display_name**: *string*
    - **enabled**: *boolean*
    - **notification_channels**: *array*
      - items: *string*
    - **severity**: *string*
    - **user_labels**: *object*
      *additional properties: String*
    - **alert_strategy**: *object*
      <br>*additional properties: false*
      - **auto_close**: *string*
      - **notification_prompts**: *string*
      - **notification_rate_limit**: *object*
        <br>*additional properties: false*
        - **period**: *string*
      - **notification_channel_strategy**: *object*
        <br>*additional properties: false*
        - **notification_channel_names**: *array*
          - items: *string*
        - **renotify_interval**: *string*
    - **conditions**: *array*
      - items: *reference([condition](#refs-condition))*
    - **documentation**: *object*
      <br>*additional properties: false*
      - **content**: *string*
      - **mime_type**: *string*
      - **subject**: *string*
      - **links**: *array*
        - items: *object*
          <br>*additional properties: false*
          - **display_name**: *string*
          - **url**: *string*
- **logging_metrics**<a name="refs-logging_metrics"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**filter**: *string*
    - **bucket_name**: *string*
    - **description**: *string*
    - **disabled**: *boolean*
    - **label_extractors**: *object*
      *additional properties: String*
    - **value_extractor**: *string*
    - **bucket_options**: *object*
      <br>*additional properties: false*
      - **explicit_buckets**: *object*
        <br>*additional properties: false*
        - **bounds**: *array*
          - items: *number*
      - **exponential_buckets**: *object*
        <br>*additional properties: false*
        - **num_finite_buckets**: *number*
        - **growth_factor**: *number*
        - **scale**: *number*
      - **linear_buckets**: *object*
        <br>*additional properties: false*
        - **num_finite_buckets**: *number*
        - **width**: *number*
        - **offset**: *number*
    - **metric_descriptor**: *object*
      <br>*additional properties: false*
      - ⁺**metric_kind**: *string*
      - ⁺**value_type**: *string*
      - **display_name**: *string*
      - **unit**: *string*
      - **labels**: *array*
        - items: *object*
          <br>*additional properties: false*
          - ⁺**key**: *string*
          - **description**: *string*
          - **value_type**: *string*
- **notification_channels**<a name="refs-notification_channels"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**type**: *string*
    - **description**: *string*
    - **display_name**: *string*
    - **enabled**: *boolean*
    - **labels**: *object*
      *additional properties: String*
    - **user_labels**: *object*
      *additional properties: String*
    - **sensitive_labels**: *object*
      <br>*additional properties: false*
      - **auth_token**: *string*
      - **password**: *string*
      - **service_key**: *string*
- **condition**<a name="refs-condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**display_name**: *string*
  - **condition_absent**: *reference([absent_condition](#refs-absent_condition))*
  - **condition_matched_log**: *reference([matched_log_condition](#refs-matched_log_condition))*
  - **condition_monitoring_query_language**: *reference([monitoring_query_condition](#refs-monitoring_query_condition))*
  - **condition_prometheus_query_language**: *reference([prometheus_query_condition](#refs-prometheus_query_condition))*
  - **condition_threshold**: *reference([threshold_condition](#refs-threshold_condition))*
- **absent_condition**<a name="refs-absent_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**duration**: *string*
  - **filter**: *string*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **matched_log_condition**<a name="refs-matched_log_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**filter**: *string*
  - **label_extractors**: *object*
    *additional properties: String*
- **monitoring_query_condition**<a name="refs-monitoring_query_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**duration**: *string*
  - ⁺**query**: *string*
  - **evaluation_missing_data**: *string*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **prometheus_query_condition**<a name="refs-prometheus_query_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**query**: *string*
  - **alert_rule**: *string*
  - **disable_metric_validation**: *boolean*
  - **duration**: *string*
  - **evaluation_interval**: *string*
  - **labels**: *object*
    *additional properties: String*
  - **rule_group**: *string*
- **threshold_condition**<a name="refs-threshold_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**comparison**: *string*
  - ⁺**duration**: *string*
  - **denominator_filter**: *string*
  - **evaluation_missing_data**: *string*
  - **filter**: *string*
  - **threshold_value**: *number*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **denominator_aggregations**: *reference([aggregations](#refs-aggregations))*
  - **forecast_options**: *object*
    <br>*additional properties: false*
    - **forecast_horizon**: *string*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **aggregations**<a name="refs-aggregations"></a>: *object*
  <br>*additional properties: false*
  - **per_series_aligner**: *string*
  - **group_by_fields**: *array*
    - items: *string*
  - **cross_series_reducer**: *string*
  - **alignment_period**: *string*
- **trigger**<a name="refs-trigger"></a>: *object*
  <br>*additional properties: false*
  - **count**: *number*
  - **percent**: *number*
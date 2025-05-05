# Observability Schema

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **alerts**: *reference([alerts](#refs-alerts))*
- **logging_metrics**: *reference([logging_metrics](#refs-logging_metrics))*
- **notification_channels**: *reference([notification_channels](#refs-notification_channels))*

## Definitions

- **alerts**<a name="refs-alerts"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - ⁺**combiner**: *string*
    - **display_name**: *string*
    - **enabled**: *boolean*
    - **notification_channels**: *array*
      - items: *string*
    - **severity**: *string*
    - **user_labels**: *object*
      *additional properties: String*
    - **alert_strategy**: *object*
      <br>*no additional properties allowed*
      - **auto_close**: *string*
      - **notification_prompts**: *string*
      - **notification_rate_limit**: *object*
        <br>*no additional properties allowed*
        - **period**: *string*
      - **notification_channel_strategy**: *object*
        <br>*no additional properties allowed*
        - **notification_channel_names**: *array*
          - items: *string*
        - **renotify_interval**: *string*
    - **conditions**: *array*
      - items: *reference([condition](#refs-condition))*
    - **documentation**: *object*
      <br>*no additional properties allowed*
      - **content**: *string*
      - **mime_type**: *string*
      - **subject**: *string*
      - **links**: *array*
        - items: *object*
          <br>*no additional properties allowed*
          - **display_name**: *string*
          - **url**: *string*
- **logging_metrics**<a name="refs-logging_metrics"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - ⁺**filter**: *string*
    - **bucket_name**: *string*
    - **description**: *string*
    - **disabled**: *boolean*
    - **label_extractors**: *object*
      *additional properties: String*
    - **value_extractor**: *string*
    - **bucket_options**: *object*
      <br>*no additional properties allowed*
      - **explicit_buckets**: *object*
        <br>*no additional properties allowed*
        - **bounds**: *array*
          - items: *number*
      - **exponential_buckets**: *object*
        <br>*no additional properties allowed*
        - **num_finite_buckets**: *number*
        - **growth_factor**: *number*
        - **scale**: *number*
      - **linear_buckets**: *object*
        <br>*no additional properties allowed*
        - **num_finite_buckets**: *number*
        - **width**: *number*
        - **offset**: *number*
    - **metric_descriptor**: *object*
      <br>*no additional properties allowed*
      - ⁺**metric_kind**: *string*
      - ⁺**value_type**: *string*
      - **display_name**: *string*
      - **unit**: *string*
      - **labels**: *array*
        - items: *object*
          <br>*no additional properties allowed*
          - ⁺**key**: *string*
          - **description**: *string*
          - **value_type**: *string*
- **notification_channels**<a name="refs-notification_channels"></a>: *object*
  <br>*no additional properties allowed*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*no additional properties allowed*
    - ⁺**type**: *string*
    - **description**: *string*
    - **display_name**: *string*
    - **enabled**: *boolean*
    - **labels**: *object*
      *additional properties: String*
    - **user_labels**: *object*
      *additional properties: String*
    - **sensitive_labels**: *object*
      <br>*no additional properties allowed*
      - **auth_token**: *string*
      - **password**: *string*
      - **service_key**: *string*
- **condition**<a name="refs-condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**display_name**: *string*
  - **condition_absent**: *reference([absent_condition](#refs-absent_condition))*
  - **condition_matched_log**: *reference([matched_log_condition](#refs-matched_log_condition))*
  - **condition_monitoring_query_language**: *reference([monitoring_query_condition](#refs-monitoring_query_condition))*
  - **condition_prometheus_query_language**: *reference([prometheus_query_condition](#refs-prometheus_query_condition))*
  - **condition_threshold**: *reference([threshold_condition](#refs-threshold_condition))*
- **absent_condition**<a name="refs-absent_condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**duration**: *string*
  - **filter**: *string*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **matched_log_condition**<a name="refs-matched_log_condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**filter**: *string*
  - **label_extractors**: *object*
    *additional properties: String*
- **monitoring_query_condition**<a name="refs-monitoring_query_condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**duration**: *string*
  - ⁺**query**: *string*
  - **evaluation_missing_data**: *string*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **prometheus_query_condition**<a name="refs-prometheus_query_condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**query**: *string*
  - **alert_rule**: *string*
  - **disable_metric_validation**: *boolean*
  - **duration**: *string*
  - **evaluation_interval**: *string*
  - **labels**: *object*
    *additional properties: String*
  - **rule_group**: *string*
- **threshold_condition**<a name="refs-threshold_condition"></a>: *object*
  <br>*no additional properties allowed*
  - ⁺**comparison**: *string*
  - ⁺**duration**: *string*
  - **denominator_filter**: *string*
  - **evaluation_missing_data**: *string*
  - **filter**: *string*
  - **threshold_value**: *number*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **denominator_aggregations**: *reference([aggregations](#refs-aggregations))*
  - **forecast_options**: *object*
    <br>*no additional properties allowed*
    - **forecast_horizon**: *string*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **aggregations**<a name="refs-aggregations"></a>: *object*
  <br>*no additional properties allowed*
  - **per_series_aligner**: *string*
  - **group_by_fields**: *array*
    - items: *string*
  - **cross_series_reducer**: *string*
  - **alignment_period**: *string*
- **trigger**<a name="refs-trigger"></a>: *object*
  <br>*no additional properties allowed*
  - **count**: *number*
  - **percent**: *number*
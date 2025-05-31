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
      <br>*pattern: None*
    - **display_name**: *string*
      <br>*pattern: None*
    - **enabled**: *boolean*
    - **notification_channels**: *array*
      - items: *string*
        <br>*pattern: None*
    - **severity**: *string*
      <br>*pattern: None*
    - **user_labels**: *object*
      *additional properties: String*
    - **alert_strategy**: *object*
      <br>*additional properties: false*
      - **auto_close**: *string*
        <br>*pattern: None*
      - **notification_prompts**: *string*
        <br>*pattern: None*
      - **notification_rate_limit**: *object*
        <br>*additional properties: false*
        - **period**: *string*
          <br>*pattern: None*
      - **notification_channel_strategy**: *object*
        <br>*additional properties: false*
        - **notification_channel_names**: *array*
          - items: *string*
            <br>*pattern: None*
        - **renotify_interval**: *string*
          <br>*pattern: None*
    - **conditions**: *array*
      - items: *reference([condition](#refs-condition))*
    - **documentation**: *object*
      <br>*additional properties: false*
      - **content**: *string*
        <br>*pattern: None*
      - **mime_type**: *string*
        <br>*pattern: None*
      - **subject**: *string*
        <br>*pattern: None*
      - **links**: *array*
        - items: *object*
          <br>*additional properties: false*
          - **display_name**: *string*
            <br>*pattern: None*
          - **url**: *string*
            <br>*pattern: None*
- **logging_metrics**<a name="refs-logging_metrics"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**filter**: *string*
      <br>*pattern: None*
    - **bucket_name**: *string*
      <br>*pattern: None*
    - **description**: *string*
      <br>*pattern: None*
    - **disabled**: *boolean*
    - **label_extractors**: *object*
      *additional properties: String*
    - **value_extractor**: *string*
      <br>*pattern: None*
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
        <br>*pattern: None*
      - ⁺**value_type**: *string*
        <br>*pattern: None*
      - **display_name**: *string*
        <br>*pattern: None*
      - **unit**: *string*
        <br>*pattern: None*
      - **labels**: *array*
        - items: *object*
          <br>*additional properties: false*
          - ⁺**key**: *string*
            <br>*pattern: None*
          - **description**: *string*
            <br>*pattern: None*
          - **value_type**: *string*
            <br>*pattern: None*
- **notification_channels**<a name="refs-notification_channels"></a>: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**type**: *string*
      <br>*pattern: None*
    - **description**: *string*
      <br>*pattern: None*
    - **display_name**: *string*
      <br>*pattern: None*
    - **enabled**: *boolean*
    - **labels**: *object*
      *additional properties: String*
    - **user_labels**: *object*
      *additional properties: String*
    - **sensitive_labels**: *object*
      <br>*additional properties: false*
      - **auth_token**: *string*
        <br>*pattern: None*
      - **password**: *string*
        <br>*pattern: None*
      - **service_key**: *string*
        <br>*pattern: None*
- **condition**<a name="refs-condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**display_name**: *string*
    <br>*pattern: None*
  - **condition_absent**: *reference([absent_condition](#refs-absent_condition))*
  - **condition_matched_log**: *reference([matched_log_condition](#refs-matched_log_condition))*
  - **condition_monitoring_query_language**: *reference([monitoring_query_condition](#refs-monitoring_query_condition))*
  - **condition_prometheus_query_language**: *reference([prometheus_query_condition](#refs-prometheus_query_condition))*
  - **condition_threshold**: *reference([threshold_condition](#refs-threshold_condition))*
- **absent_condition**<a name="refs-absent_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**duration**: *string*
    <br>*pattern: None*
  - **filter**: *string*
    <br>*pattern: None*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **matched_log_condition**<a name="refs-matched_log_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**filter**: *string*
    <br>*pattern: None*
  - **label_extractors**: *object*
    *additional properties: String*
- **monitoring_query_condition**<a name="refs-monitoring_query_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**duration**: *string*
    <br>*pattern: None*
  - ⁺**query**: *string*
    <br>*pattern: None*
  - **evaluation_missing_data**: *string*
    <br>*pattern: None*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **prometheus_query_condition**<a name="refs-prometheus_query_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**query**: *string*
    <br>*pattern: None*
  - **alert_rule**: *string*
    <br>*pattern: None*
  - **disable_metric_validation**: *boolean*
  - **duration**: *string*
    <br>*pattern: None*
  - **evaluation_interval**: *string*
    <br>*pattern: None*
  - **labels**: *object*
    *additional properties: String*
  - **rule_group**: *string*
    <br>*pattern: None*
- **threshold_condition**<a name="refs-threshold_condition"></a>: *object*
  <br>*additional properties: false*
  - ⁺**comparison**: *string*
    <br>*pattern: None*
  - ⁺**duration**: *string*
    <br>*pattern: None*
  - **denominator_filter**: *string*
    <br>*pattern: None*
  - **evaluation_missing_data**: *string*
    <br>*pattern: None*
  - **filter**: *string*
    <br>*pattern: None*
  - **threshold_value**: *number*
  - **aggregations**: *reference([aggregations](#refs-aggregations))*
  - **denominator_aggregations**: *reference([aggregations](#refs-aggregations))*
  - **forecast_options**: *object*
    <br>*additional properties: false*
    - **forecast_horizon**: *string*
      <br>*pattern: None*
  - **trigger**: *reference([trigger](#refs-trigger))*
- **aggregations**<a name="refs-aggregations"></a>: *object*
  <br>*additional properties: false*
  - **per_series_aligner**: *string*
    <br>*pattern: None*
  - **group_by_fields**: *array*
    - items: *string*
      <br>*pattern: None*
  - **cross_series_reducer**: *string*
    <br>*pattern: None*
  - **alignment_period**: *string*
    <br>*pattern: None*
- **trigger**<a name="refs-trigger"></a>: *object*
  <br>*additional properties: false*
  - **count**: *number*
  - **percent**: *number*

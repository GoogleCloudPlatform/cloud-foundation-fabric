/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
variable "alerts" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    alert_strategy = optional(object({
      auto_close           = optional(string)
      notification_prompts = optional(string)
      notification_rate_limit = optional(object({
        period = optional(string)
      }))
      notification_channel_strategy = optional(object({
        notification_channel_names = optional(list(string))
        renotify_interval          = optional(string)
      }))
    }))
    combiner = string
    conditions = object({
      condition_matched_log = optional(object({
        filter           = string
        label_extractors = optional(map(string))
      }))
      condition_monitoring_query_language = optional(object({
        query    = string
        duration = string
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        display_name            = string
        evaluation_missing_data = optional(string)
      }))
      condition_threshold = optional(object({
        aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        comparison         = string
        denominator_filter = optional(string)
        denominator_aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        duration                = string
        evaluation_missing_data = optional(string)
        forecast_options = optional(object({
          forecast_horizon = string
        }))
        filter          = optional(string)
        threshold_value = optional(number)
        resource_type   = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_absent = optional(object({
        aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        duration = string
        filter   = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
    })
    description  = optional(string)
    display_name = optional(string)
    documentation = optional(object({
      content   = optional(string)
      mime_type = optional(string)
      subject   = optional(string)
      links = optional(list(object({
        display_name = optional(string)
        url          = optional(string)
      })))
    }))
    filter                = string
    name                  = string
    notification_channels = optional(list(string))
    trigger_count         = optional(number)
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.alerts :
      contains(["AND", "OR", "AND_WITH_MATCHING_RESOURCE"], v.combiner)
    ])
    error_message = "Combiner must be one of 'AND', 'OR', 'AND_WITH_MATCHING_RESOURCE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.alerts :
      contains(["ALIGN_NONE", "ALIGN_DELTA", "ALIGN_RATE", "ALIGN_INTERPOLATE", "ALIGN_NEXT_OLDER", "ALIGN_MIN", "ALIGN_MAX",
        "ALIGN_MEAN", "ALIGN_COUNT", "ALIGN_SUM", "ALIGN_STDDEV", "ALIGN_COUNT_TRUE", "ALIGN_COUNT_FALSE", "ALIGN_COUNT_FALSE",
      "ALIGN_PERCENTILE_99", "ALIGN_PERCENTILE_95", "ALIGN_PERCENTILE_50", "ALIGN_PERCENTILE_05", "ALIGN_PERCENT_CHANGE"], v.aggregations.per_series_aligner)
    ])
    error_message = "Aggregation: Per Series Aligner must be one of 'ALIGN_NONE', 'ALIGN_DELTA', 'ALIGN_RATE', 'ALIGN_INTERPOLATE', 'ALIGN_NEXT_OLDER', 'ALIGN_MIN', 'ALIGN_MAX','ALIGN_MEAN', 'ALIGN_COUNT', 'ALIGN_SUM', 'ALIGN_STDDEV', 'ALIGN_COUNT_TRUE', 'ALIGN_COUNT_FALSE', 'ALIGN_COUNT_FALSE', 'ALIGN_PERCENTILE_99', 'ALIGN_PERCENTILE_95', 'ALIGN_PERCENTILE_50', 'ALIGN_PERCENTILE_05', 'ALIGN_PERCENT_CHANGE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.alerts :
      contains(["EVALUATION_MISSING_DATA_INACTIVE", "EVALUATION_MISSING_DATA_ACTIVE", "EVALUATION_MISSING_DATA_NO_OP"], v.conditions.condition_monitoring_query_language.evaluation_missing_data)
    ])
    error_message = "conditions.condition_monitoring_query_language.evaluation_missing_data must be one of 'EVALUATION_MISSING_DATA_INACTIVE', 'EVALUATION_MISSING_DATA_ACTIVE', 'EVALUATION_MISSING_DATA_NO_OP'."
  }
  validation {
    condition = alltrue([
      for k, v in var.alerts :
      contains(["COMPARISON_GT", "COMPARISON_GE", "COMPARISON_LT", "COMPARISON_LE", "COMPARISON_EQ", "COMPARISON_NE"], v.conditions.condition_threshold.comparison)
    ])
    error_message = "conditions.condition_threshold.comparison must be one of 'COMPARISON_GT', 'COMPARISON_GE', 'COMPARISON_LT', 'COMPARISON_LE', 'COMPARISON_EQ', 'COMPARISON_NE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.alerts :
      contains(["EVALUATION_MISSING_DATA_INACTIVE", "EVALUATION_MISSING_DATA_ACTIVE", "EVALUATION_MISSING_DATA_NO_OP"], v.conditions.condition_threshold.evaluation_missing_data)
    ])
    error_message = "conditions.condition_monitoring_query_language.evaluation_missing_data must be one of 'EVALUATION_MISSING_DATA_INACTIVE', 'EVALUATION_MISSING_DATA_ACTIVE', 'EVALUATION_MISSING_DATA_NO_OP'."
  }
}

variable "logging_metrics" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    bucket_name      = optional(string)
    disabled         = optional(bool)
    description      = optional(string)
    filter           = string
    label_extractors = optional(map(string))
    labels = list(object({
      key         = string
      description = optional(string)
      value_type  = optional(string)
    }))
    metric_descriptor = optional(map(object({
      metric_kind = string
      value_type  = string
      labels = list(object({
        key         = string
        description = optional(string)
        value_type  = optional(string)
      }))
      name            = optional(string)
      value_extractor = optional(string)
      unit            = optional(string)
    })))
    bucket_options = optional(object({
      linear_buckets = optional(object({
        num_finite_buckets = number
        width              = number
        offset             = number
      }))
      exponential_buckets = optional(object({
        num_finite_buckets = number
        growth_factor      = number
        scale              = number
      }))
      explicit_buckets = object({
        bounds = list(number)
      })
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.logging_metrics :
      contains(["INT64", "DOUBLE", "DISTRIBUTION"], v.metric_descriptor.unit)
    ])
    error_message = "metric_descriptor.unit must be one of 'INT64', 'DOUBLE', 'DISTRIBUTION'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_metrics :
      contains(["BOOL", "INT64", "DOUBLE", "STRING", "DISTRIBUTION", "MONEY"], v.metric_descriptor.value_type)
    ])
    error_message = "metric_descriptor.unit must be one of 'BOOL', 'INT64', 'DOUBLE', 'STRING', 'DISTRIBUTION', 'MONEY'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_metrics :
      contains(["DELTA", "GAUGE", "CUMULATIVE"], v.metric_descriptor.metric_kind)
    ])
    error_message = "metric_descriptor.unit must be one of 'DELTA', 'GAUGE', 'CUMULATIVE'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_metrics :
      contains(["BOOL", "INT64", "STRING"], v.labels.value_type)
    ])
    error_message = "metric_descriptor.unit must be one of 'BOOL', 'INT64', 'STRING'."
  }
}

variable "notification_channels" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    description  = optional(string)
    display_name = optional(string)
    labels       = optional(map(string))
    type         = string
    user_labels  = optional(map(string))
    enabled      = optional(bool)
    sensitive_labels = optional(list(object({
      auth_token  = optional(string)
      password    = optional(string)
      service_key = optional(string)
    })))
  }))
  nullable = false
  default  = {}
}

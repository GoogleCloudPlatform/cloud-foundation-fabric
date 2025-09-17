/**
 * Copyright 2025 Google LLC
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
  description = "Monitoring alerts."
  type = map(object({
    combiner              = string
    display_name          = optional(string)
    enabled               = optional(bool)
    notification_channels = optional(list(string), [])
    severity              = optional(string)
    user_labels           = optional(map(string))
    alert_strategy = optional(object({
      auto_close           = optional(string)
      notification_prompts = optional(list(string))
      notification_rate_limit = optional(object({
        period = optional(string)
      }))
      notification_channel_strategy = optional(object({
        notification_channel_names = optional(list(string))
        renotify_interval          = optional(string)
      }))
    }))
    conditions = optional(list(object({
      display_name = string
      condition_absent = optional(object({
        duration = string
        filter   = optional(string)
        aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_matched_log = optional(object({
        filter           = string
        label_extractors = optional(map(string))
      }))
      condition_monitoring_query_language = optional(object({
        duration                = string
        query                   = string
        evaluation_missing_data = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
      condition_prometheus_query_language = optional(object({
        query                     = string
        alert_rule                = optional(string)
        disable_metric_validation = optional(bool)
        duration                  = optional(string)
        evaluation_interval       = optional(string)
        labels                    = optional(map(string))
        rule_group                = optional(string)
      }))
      condition_threshold = optional(object({
        comparison              = string
        duration                = string
        denominator_filter      = optional(string)
        evaluation_missing_data = optional(string)
        filter                  = optional(string)
        threshold_value         = optional(number)
        aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        denominator_aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        forecast_options = optional(object({
          forecast_horizon = string
        }))
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
      }))
    })), [])
    documentation = optional(object({
      content   = optional(string)
      mime_type = optional(string)
      subject   = optional(string)
      links = optional(list(object({
        display_name = optional(string)
        url          = optional(string)
      })))
    }))
  }))
  nullable = false
  default  = {}
}

variable "log_scopes" {
  description = "Log scopes under this project."
  type = map(object({
    description    = optional(string)
    resource_names = list(string)
  }))
  nullable = false
  default  = {}
}

variable "logging_data_access" {
  description = "Control activation of data access logs. The special 'allServices' key denotes configuration for all services."
  type = map(object({
    ADMIN_READ = optional(object({ exempted_members = optional(list(string)) })),
    DATA_READ  = optional(object({ exempted_members = optional(list(string)) })),
    DATA_WRITE = optional(object({ exempted_members = optional(list(string)) }))
  }))
  default  = {}
  nullable = false
}

variable "logging_exclusions" {
  description = "Logging exclusions for this project in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging_metrics" {
  description = "Log-based metrics."
  type = map(object({
    filter           = string
    bucket_name      = optional(string)
    description      = optional(string)
    disabled         = optional(bool)
    label_extractors = optional(map(string))
    value_extractor  = optional(string)
    bucket_options = optional(object({
      explicit_buckets = optional(object({
        bounds = list(number)
      }))
      exponential_buckets = optional(object({
        num_finite_buckets = number
        growth_factor      = number
        scale              = number
      }))
      linear_buckets = optional(object({
        num_finite_buckets = number
        width              = number
        offset             = number
      }))
    }))
    metric_descriptor = optional(object({
      metric_kind  = string
      value_type   = string
      display_name = optional(string)
      unit         = optional(string)
      labels = optional(list(object({
        key         = string
        description = optional(string)
        value_type  = optional(string)
      })), [])
    }))
  }))
  nullable = false
  default  = {}
}

variable "logging_sinks" {
  description = "Logging sinks to create for this project."
  type = map(object({
    bq_partitioned_table = optional(bool, false)
    description          = optional(string)
    destination          = string
    disabled             = optional(bool, false)
    exclusions           = optional(map(string), {})
    filter               = optional(string)
    iam                  = optional(bool, true)
    type                 = string
    unique_writer        = optional(bool, true)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "project", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'project', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

variable "metric_scopes" {
  description = "List of projects that will act as metric scopes for this project."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "notification_channels" {
  description = "Monitoring notification channels."
  type = map(object({
    type         = string
    description  = optional(string)
    display_name = optional(string)
    enabled      = optional(bool)
    labels       = optional(map(string))
    user_labels  = optional(map(string))
    sensitive_labels = optional(object({
      auth_token  = optional(string)
      password    = optional(string)
      service_key = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

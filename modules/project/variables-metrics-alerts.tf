variable "alerts" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    name                  = optional(string)
    description           = optional(string)
    filter                = optional(string)
    display_name          = optional(string)
    condition_threshold   = optional(map(string))
    trigger_count         = optional(number)
    combiner              = optional(string)
    notification_channels = optional(list(string))
    documentation = optional(object({
      content   = optional(string)
      mime_type = optional(string)
      subject   = optional(string)
      links = optional(list(object({
        display_name = optional(string)
        url          = optional(string)
      })))
    }))
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
    conditions = optional(object({
      display_name = optional(string)
      condition_matched_log = optional(object({
        filter           = optional(string)
        label_extractors = optional(map(string))
      }))
      condition_monitoring_query_language = optional(object({
        query    = optional(string)
        duration = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        evaluation_missing_data = optional(string)
      }))
      condition_threshold = optional(object({
        threshold_value    = optional(number)
        denominator_filter = optional(string)
        denominator_aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
        forecast_options = optional(object({
          forecast_horizon = optional(string)
        }))
        comparison              = optional(string)
        duration                = optional(string)
        filter                  = optional(string)
        evaluation_missing_data = optional(string)
        resource_type           = optional(string)
        trigger = optional(object({
          count   = optional(number)
          percent = optional(number)
        }))
        aggregations = optional(object({
          per_series_aligner   = optional(string)
          group_by_fields      = optional(list(string))
          cross_series_reducer = optional(string)
          alignment_period     = optional(string)
        }))
      }))
      condition_absent = optional(object({
        filter = optional(string)
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
        duration = optional(string)
      }))

    }))
  }))
  nullable = false
  default  = {}
}

variable "logging_metrics" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    name             = optional(string)
    description      = optional(string)
    filter           = optional(string)
    bucket_name      = optional(string)
    value_extractor  = optional(string)
    label_extractors = optional(map(string))
    disabled         = optional(bool)
    metric_descriptor = optional(map(object({
      metric_kind = optional(string)
      value_type  = optional(string)
      labels = list(object({
        key         = optional(string)
        description = optional(string)
        value_type  = optional(string)
      }))
    })))
    bucket_options = optional(object({
      linear_buckets = optional(object({
        num_finite_buckets = optional(number)
        width              = optional(number)
        offset             = optional(number)
      }))
      exponential_buckets = optional(object({
        num_finite_buckets = optional(number)
        growth_factor      = optional(number)
        scale              = optional(number)
      }))
      explicit_buckets = optional(object({
        bounds = optional(list(number))
      }))
    }))
  }))
  nullable = false
  default  = {}
}

variable "channels" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    type          = optional(string)
    email_address = optional(string)
    labels        = optional(map(string))
    description   = optional(string)
    display_name  = optional(string)
    user_labels   = optional(map(string))
    sensitive_labels = optional(list(object({
      auth_token  = optional(string)
      password    = optional(string)
      service_key = optional(string)
    })))
    enabled = optional(bool)
  }))
  nullable = false
  default  = {}
}

variable "logging_metrics_alerts" {
  description = "Logging metrics alerts configuration."
  type = map(object({
    name                  = optional(string)
    description           = optional(string)
    filter                = optional(string)
    display_name          = optional(string)
    metric_descriptor     = optional(map(string))
    condition_threshold   = optional(map(string))
    trigger_count         = optional(number)
    aggregations          = optional(map(string))
    combiner              = optional(string)
    notification_channels = optional(list(string))
  }))
  nullable = false
  default  = {}
}

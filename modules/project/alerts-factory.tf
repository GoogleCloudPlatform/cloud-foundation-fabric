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

locals {
  _alerts_factory_data_raw = merge([
    for f in try(fileset(var.factories_config.alerts, "*.yaml"), []) :
    yamldecode(file("${var.factories_config.alerts}/${f}"))
  ]...)
  _alerts_factory_data = {
    for k, v in local._alerts_factory_data_raw :
    k => merge({
      name                  = k
      filter                = null
      display_name          = null
      condition_threshold   = {}
      trigger_count         = null
      combiner              = null
      notification_channels = []
      conditions = {
        display_name                        = null
        condition_matched_log               = null
        condition_monitoring_query_language = null
        condition_threshold                 = {}
        condition_absent                    = null
      }
      alert_strategy = null
      documentation  = null
    }, v)
  }
  alerts = merge(local._alerts_factory_data, var.logging_metrics)
}

resource "google_monitoring_alert_policy" "default" {
  for_each = local.alerts
  project  = "jetstack-joshua-wright"
  # project      = local.project.project_id
  combiner     = each.value.combiner
  display_name = each.value.display_name
  conditions {
    display_name = each.value.display_name
    dynamic "condition_matched_log" {
      for_each = lookup(each.value.conditions, "condition_matched_log", null)[*]
      content {
        filter           = each.value.conditions.condition_matched_log.filter
        label_extractors = each.value.conditions.condition_matched_log.label_extractors
      }
    }
    dynamic "condition_monitoring_query_language" {
      for_each = lookup(each.value.conditions, "condition_monitoring_query_language", null)[*]
      content {
        query    = each.value.conditions.condition_monitoring_query_language.query
        duration = each.value.conditions.condition_monitoring_query_language.duration
        trigger {
          count   = try(each.value.conditions.condition_monitoring_query_language.trigger.count, null)
          percent = try(each.value.conditions.condition_monitoring_query_language.trigger.percent, null)
        }
        evaluation_missing_data = each.value.conditions.condition_monitoring_query_language.evaluation_missing_data
      }
    }
    dynamic "condition_absent" {
      for_each = lookup(each.value.conditions, "condition_absent", null)[*]
      content {
        filter = each.value.conditions.condition_absent.filter
        trigger {
          count   = try(each.value.conditions.condition_absent.trigger.count, null)
          percent = try(each.value.conditions.condition_absent.trigger.percent, null)
        }
        aggregations {
          per_series_aligner   = try(each.value.conditions.condition_absent.aggregations.per_series_aligner, null)
          group_by_fields      = try(each.value.conditions.condition_absent.aggregations.group_by_fields, [])
          cross_series_reducer = try(each.value.conditions.condition_absent.aggregations.cross_series_reducer, null)
          alignment_period     = try(each.value.conditions.condition_absent.aggregations.alignment_period, null)
        }
        duration = each.value.conditions.condition_absent.duration
      }
    }
    dynamic "condition_threshold" {
      for_each = lookup(each.value.conditions, "condition_threshold", null)[*]
      content {
        threshold_value    = try(each.value.condition_threshold.threshold_value, null)
        denominator_filter = try(each.value.condition_threshold.denominator_filter, null)
        dynamic "denominator_aggregations" {
          for_each = try(each.value.condition_threshold.denominator_aggregations, null)[*]
          content {
            per_series_aligner = try(each.value.conditions.condition_threshold.denominator_aggregations.per_series_aligner, null)
            group_by_fields    = try(each.value.conditions.condition_threshold.denominator_aggregations.group_by_fields, [])
            alignment_period   = try(each.value.conditions.condition_threshold.denominator_aggregations.alignment_period, null)
          }
        }
        dynamic "forecast_options" {
          for_each = try(each.value.conditions.condition_threshold.forecast_options, null)[*]
          content {
            forecast_horizon = try(each.value.conditions.condition_threshold.forecast_options.forecast_horizon, null)
          }
        }
        comparison              = try(each.value.conditions.condition_threshold.comparison, null)
        duration                = try(each.value.conditions.condition_threshold.duration, null)
        evaluation_missing_data = try(each.value.conditions.condition_threshold.evaluation_missing_data, null)
        filter                  = try("resource.type = \"${each.value.conditions.condition_threshold.resource_type}\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.default[each.value.name].name}\"", each.value.conditions.condition_threshold.filter)
        trigger {
          count   = try(each.value.conditions.condition_threshold.trigger.count, null)
          percent = try(each.value.conditions.condition_threshold.trigger.percent, null)
        }
        aggregations {
          per_series_aligner   = try(each.value.conditions.condition_threshold.aggregations.per_series_aligner, null)
          group_by_fields      = try(each.value.conditions.condition_threshold.aggregations.group_by_fields, [])
          cross_series_reducer = try(each.value.conditions.condition_threshold.aggregations.cross_series_reducer, null)
          alignment_period     = try(each.value.conditions.condition_threshold.aggregations.alignment_period, null)
        }
      }
    }
  }
  notification_channels = [
    try(google_monitoring_notification_channel.this[each.value.notification_channels].id,
    each.value.notification_channels),
    try(google_monitoring_notification_channel.default[0].id, null)
  ]
  dynamic "alert_strategy" {
    for_each = lookup(each.value, "alert_strategy", null)[*]
    content {
      auto_close           = try(each.value.alert_strategy.auto_close, "604800s")
      notification_prompts = try(each.value.alert_strategy.notification_prompts, null)
      dynamic "notification_rate_limit" {
        for_each = try(each.value.alert_strategy.notification_rate_limit, null)[*]
        content {
          period = try(each.value.alert_strategy.notification_rate_limit.period, null)
        }
      }
      dynamic "notification_channel_strategy" {
        for_each = try(each.value.alert_strategy.notification_channel_strategy, null)[*]
        content {
          notification_channel_names = try(each.value.alert_strategy.notification_channel_strategy.notification_channel_names, [])
          renotify_interval          = try(each.value.alert_strategy.notification_channel_strategy.renotify_interval, null)
        }
      }
    }
  }
  dynamic "documentation" {
    for_each = lookup(each.value, "documentation", null)[*]
    content {
      content   = try(each.value.documentation.content, null)
      mime_type = try(each.value.documentation.mime_type, null)
      subject   = try(each.value.documentation.subject, null)
      dynamic "links" {
        for_each = try(each.value.documentation.links, [])
        content {
          display_name = try(links.value.display_name, null)
          url          = try(links.value.url, null)
        }
      }
    }
  }
}

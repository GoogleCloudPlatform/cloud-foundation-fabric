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

locals {
  _alerts_factory_data_raw = merge([
    for k in local.observability_factory_data_raw :
    lookup(k, "alerts", {})
  ]...)
  _alerts_factory_data = {
    for k, v in local._alerts_factory_data_raw :
    k => {
      combiner              = v.combiner
      display_name          = try(v.display_name, null)
      enabled               = try(v.enabled, null)
      notification_channels = try(v.notification_channels, [])
      severity              = try(v.severity, null)
      user_labels           = try(v.user_labels, null)
      alert_strategy = !can(v.alert_strategy) ? null : {
        auto_close           = try(v.alert_strategy.auto_close, null)
        notification_prompts = try(v.alert_strategy.notification_prompts, null)
        notification_rate_limit = !can(v.alert_strategy.notification_rate_limit) ? null : {
          period = try(v.alert_strategy.notification_rate_limit.period, null)
        }
        notification_channel_strategy = !can(v.alert_strategy.notification_channel_strategy) ? null : {
          notification_channel_names = try(v.alert_strategy.notification_channel_strategy.notification_channel_names, null)
          renotify_interval          = try(v.alert_strategy.notification_channel_strategy.renotify_interval, null)
        }
      }
      conditions = !can(v.conditions) ? null : [
        for c in v.conditions : {
          display_name = c.display_name
          condition_absent = !can(c.condition_absent) ? null : {
            duration = c.condition_absent.duration
            filter   = try(c.condition_absent.filter, null)
            aggregations = !can(c.condition_absent.aggregations) ? null : {
              per_series_aligner   = try(c.condition_absent.aggregations.per_series_aligner, null)
              group_by_fields      = try(c.condition_absent.aggregations.group_by_fields, null)
              cross_series_reducer = try(c.condition_absent.aggregations.cross_series_reducer, null)
              alignment_period     = try(c.condition_absent.aggregations.alignment_period, null)
            }
            trigger = !can(c.condition_absent.trigger) ? null : {
              count   = try(c.condition_absent.trigger.count, null)
              percent = try(c.condition_absent.trigger.percent, null)
            }
          }
          condition_matched_log = !can(c.condition_matched_log) ? null : {
            filter           = c.condition_matched_log.filter
            label_extractors = try(c.condition_matched_log.label_extractors, null)
          }
          condition_monitoring_query_language = !can(c.condition_monitoring_query_language) ? null : {
            duration                = c.condition_monitoring_query_language.duration
            query                   = c.condition_monitoring_query_language.query
            evaluation_missing_data = try(c.condition_monitoring_query_language.evaluation_missing_data, null)
            trigger = !can(c.condition_monitoring_query_language.trigger) ? null : {
              count   = try(c.condition_monitoring_query_language.trigger.count, null)
              percent = try(c.condition_monitoring_query_language.trigger.percent, null)
            }
          }
          condition_prometheus_query_language = !can(c.condition_prometheus_query_language) ? null : {
            query                     = c.condition_prometheus_query_language.query
            alert_rule                = try(c.condition_prometheus_query_language.alert_rule, null)
            disable_metric_validation = try(c.condition_prometheus_query_language.disable_metric_validation, null)
            duration                  = try(c.condition_prometheus_query_language.duration, null)
            evaluation_interval       = try(c.condition_prometheus_query_language.evaluation_interval, null)
            labels                    = try(c.condition_prometheus_query_language.labels, null)
            rule_group                = try(c.condition_prometheus_query_language.rule_group, null)
          }
          condition_threshold = !can(c.condition_threshold) ? null : {
            comparison         = c.condition_threshold.comparison
            duration           = c.condition_threshold.duration
            denominator_filter = try(c.condition_threshold.denominator_filter, null)


            evaluation_missing_data = try(c.condition_threshold.evaluation_missing_data, null)
            filter                  = try(c.condition_threshold.filter, null)
            threshold_value         = try(c.condition_threshold.threshold_value, null)
            aggregations = !can(c.condition_threshold.aggregations) ? null : {
              per_series_aligner   = try(c.condition_threshold.aggregations.per_series_aligner, null)
              group_by_fields      = try(c.condition_threshold.aggregations.group_by_fields, null)
              cross_series_reducer = try(c.condition_threshold.aggregations.cross_series_reducer, null)
              alignment_period     = try(c.condition_threshold.aggregations.alignment_period, null)
            }
            denominator_aggregations = !can(c.condition_threshold.denominator_aggregations) ? null : {
              per_series_aligner   = try(c.condition_threshold.denominator_aggregations.per_series_aligner, null)
              group_by_fields      = try(c.condition_threshold.denominator_aggregations.group_by_fields, null)
              cross_series_reducer = try(c.condition_threshold.denominator_aggregations.cross_series_reducer, null)
              alignment_period     = try(c.condition_threshold.denominator_aggregations.alignment_period, null)
            }
            forecast_options = !can(c.condition_threshold.forecast_options) ? null : {
              forecast_horizon = c.condition_threshold.forecast_options.forecast_horizon
            }
            trigger = !can(c.condition_threshold.trigger) ? null : {
              count   = try(c.condition_threshold.trigger.count, null)
              percent = try(c.condition_threshold.trigger.percent, null)
            }
          }
        }
      ]
      documentation = !can(v.documentation) ? null : {
        content   = try(v.documentation.content, null)
        mime_type = try(v.documentation.mime_type, null)
        subject   = try(v.documentation.subject, null)
        links = !can(v.documentation.links) ? null : [
          for l in v.documentation.link : {
            display_name = try(l.display_name, null)
            url          = try(l.url, null)
        }]
      }
    }
  }
  alerts = merge(local._alerts_factory_data, var.alerts)
}

resource "google_monitoring_alert_policy" "alerts" {
  for_each = local.alerts
  project  = local.project.project_id

  combiner     = each.value.combiner
  display_name = each.value.display_name
  enabled      = each.value.enabled
  notification_channels = [
    for x in each.value.notification_channels :
    try(
      # first try to get a channel created by this module
      google_monitoring_notification_channel.channels[x].name,
      # otherwise check the context
      var.factories_config.context.notification_channels[x],
      # if nothing else, use the provided channel as is
      x
    )
  ]
  severity    = each.value.severity
  user_labels = each.value.user_labels

  dynamic "alert_strategy" {
    for_each = each.value.alert_strategy[*]
    content {
      auto_close           = alert_strategy.value.auto_close
      notification_prompts = alert_strategy.value.notification_prompts
      dynamic "notification_channel_strategy" {
        for_each = alert_strategy.value.notification_channel_strategy[*]
        content {
          notification_channel_names = notification_channel_strategy.value.notification_channel_names
          renotify_interval          = notification_channel_strategy.value.renotify_interval
        }
      }
      dynamic "notification_rate_limit" {
        for_each = alert_strategy.value.notification_rate_limit[*]
        content {
          period = notification_rate_limit.value.period
        }
      }
    }
  }
  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name
      dynamic "condition_absent" {
        for_each = conditions.value.condition_absent[*]
        content {
          duration = condition_absent.value.duration
          filter   = condition_absent.value.filter
          dynamic "aggregations" {
            for_each = condition_absent.value.aggregations[*]
            content {
              alignment_period     = aggregations.value.alignment_period
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
              per_series_aligner   = aggregations.value.per_series_aligner
            }
          }
          dynamic "trigger" {
            for_each = condition_absent.value.trigger[*]
            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }
        }
      }
      dynamic "condition_matched_log" {
        for_each = conditions.value.condition_matched_log[*]
        content {
          filter           = condition_matched_log.value.filter
          label_extractors = condition_matched_log.value.label_extractors
        }
      }
      dynamic "condition_monitoring_query_language" {
        for_each = conditions.value.condition_monitoring_query_language[*]
        content {
          duration                = condition_monitoring_query_language.value.duration
          query                   = condition_monitoring_query_language.value.query
          evaluation_missing_data = condition_monitoring_query_language.value.evaluation_missing_data
          trigger {
            count   = condition_monitoring_query_language.value.trigger.count
            percent = condition_monitoring_query_language.value.trigger.percent
          }
        }
      }

      dynamic "condition_prometheus_query_language" {
        for_each = conditions.value.condition_prometheus_query_language[*]
        content {
          query                     = condition_prometheus_query_language.value.query
          disable_metric_validation = condition_prometheus_query_language.value.disable_metric_validation
          duration                  = condition_prometheus_query_language.value.duration
          evaluation_interval       = condition_prometheus_query_language.value.evaluation_interval
          labels                    = condition_prometheus_query_language.value.labels
          rule_group                = condition_prometheus_query_language.value.rule_group
          alert_rule                = condition_prometheus_query_language.value.alert_rule
        }
      }
      dynamic "condition_threshold" {
        for_each = conditions.value.condition_threshold[*]
        content {
          comparison              = condition_threshold.value.comparison
          duration                = condition_threshold.value.duration
          denominator_filter      = condition_threshold.value.denominator_filter
          evaluation_missing_data = condition_threshold.value.evaluation_missing_data
          filter                  = condition_threshold.value.filter
          threshold_value         = condition_threshold.value.threshold_value
          dynamic "aggregations" {
            for_each = condition_threshold.value.aggregations[*]
            content {
              alignment_period     = aggregations.value.alignment_period
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
              per_series_aligner   = aggregations.value.per_series_aligner
            }
          }
          dynamic "denominator_aggregations" {
            for_each = condition_threshold.value.denominator_aggregations[*]
            content {
              alignment_period   = denominator_aggregations.value.alignment_period
              group_by_fields    = denominator_aggregations.value.group_by_fields
              per_series_aligner = denominator_aggregations.value.per_series_aligner
            }
          }
          dynamic "forecast_options" {
            for_each = condition_threshold.value.forecast_options[*]
            content {
              forecast_horizon = forecast_options.value.forecast_horizon
            }
          }
          dynamic "trigger" {
            for_each = condition_threshold.value.trigger[*]
            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }
        }
      }
    }
  }
  dynamic "documentation" {
    for_each = each.value.documentation[*]
    content {
      content   = documentation.value.content
      mime_type = documentation.value.mime_type
      subject   = documentation.value.subject
      dynamic "links" {
        for_each = documentation.value.links[*]
        content {
          display_name = links.value.display_name
          url          = links.value.url
        }
      }
    }
  }
}

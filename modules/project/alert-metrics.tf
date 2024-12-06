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
  _logging_metrics_alerts_factory_data_raw = merge([
    for f in try(fileset(var.factories_config.logging_metrics_alerts, "*.yaml"), []) :
    yamldecode(file("${var.factories_config.logging_metrics_alerts}/${f}"))
  ]...)
  _logging_metrics_alerts_factory_data = {
    for k, v in local._logging_metrics_alerts_factory_data_raw :
    k => merge({
      name                  = k
      description           = null
      filter                = null
      display_name          = null
      metric_descriptor     = {}
      condition_threshold   = {}
      trigger_count         = null
      aggregations          = {}
      combiner              = null
      notification_channels = []
    }, v)
  }
  logging_metrics_alerts = merge(local._logging_metrics_alerts_factory_data, var.logging_metrics_alerts)
}

resource "google_monitoring_notification_channel" "default" {
  project      = local.project.project_id
  display_name = "Default Email Notification"
  type         = "email"
  labels = {
    email_address = try(var.default_alerts_email)
  }
}

resource "google_logging_metric" "default" {
  for_each    = local.logging_metrics_alerts
  project     = local.project.project_id
  filter      = each.value.filter
  name        = each.value.name
  description = each.value.description
  metric_descriptor {
    metric_kind = each.value.metric_descriptor.metric_kind
    value_type  = each.value.metric_descriptor.value_type
  }
}

resource "google_monitoring_alert_policy" "default" {
  for_each     = local.logging_metrics_alerts
  project      = local.project.project_id
  combiner     = each.value.combiner
  display_name = each.value.display_name
  conditions {
    display_name = each.value.display_name
    condition_threshold {
      comparison = each.value.condition_threshold.comparison
      duration   = each.value.condition_threshold.duration
      filter     = try("resource.type = \"${each.value.condition_threshold.resource_type}\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.default[each.value.name].name}\"", "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.default[each.value.name].name}\"")
      trigger {
        count = each.value.trigger_count
      }
      aggregations {
        per_series_aligner   = each.value.aggregations.per_series_aligner
        cross_series_reducer = each.value.aggregations.cross_series_reducer
        alignment_period     = each.value.aggregations.alignment_period
      }
    }
  }
  notification_channels = try(split(",", google_monitoring_notification_channel.default.id),
  each.value.notification_channels)
  alert_strategy {
    auto_close = "604800s"
  }
}

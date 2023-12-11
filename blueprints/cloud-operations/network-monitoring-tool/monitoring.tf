/**
 * Copyright 2023 Google LLC
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

#######################################################################
#                     TIME-SERIES AND DASHBOARD                       #
#######################################################################

locals {
  metric_labels = {
    endpoint = {
      key         = "endpoint"
      value_type  = "STRING"
      description = "Endpoint tested (IP:PORT)."
    }
    agent = {
      key         = "agent_vm"
      value_type  = "STRING"
      description = "VM running the agent."
    }
  }
  metrics = {
    endpoint-latency = {
      description = "Endpoint latency custom metric"
      type        = "endpoint_latency"
      metric_kind = "GAUGE"
      value_type  = "INT64"
    }
    endpoint-uptime = {
      description = "Endpoint uptime check metric"
      type        = "endpoint_uptime_check_passed"
      metric_kind = "GAUGE"
      value_type  = "BOOL"
    }
  }
}

resource "google_monitoring_metric_descriptor" "custom_metrics" {
  for_each     = var.bootstrap_monitoring ? local.metrics : {}
  project      = var.monitoring_project_id
  description  = each.value["description"]
  display_name = each.key
  metric_kind  = each.value["metric_kind"]
  type         = "custom.googleapis.com/${each.value["type"]}"
  value_type   = each.value["value_type"]
  dynamic "labels" {
    for_each = local.metric_labels
    content {
      key         = labels.value["key"]
      value_type  = labels.value["value_type"]
      description = labels.value["description"]
    }
  }
}

resource "google_monitoring_dashboard" "network_monitoring_dashboard" {
  count          = var.bootstrap_monitoring ? 1 : 0
  project        = var.monitoring_project_id
  dashboard_json = file("${path.module}/dashboards/network-monitoring.json")
  lifecycle {
    ignore_changes = [dashboard_json]
  }
  depends_on = [
    google_monitoring_metric_descriptor.custom_metrics
  ]
}


#######################################################################
#                              ALERTS                                 #
#######################################################################

resource "google_monitoring_notification_channel" "email" {
  count        = var.alert_config.enabled ? 1 : 0
  project      = var.monitoring_project_id
  display_name = "Network Operation Notification Channel"
  type         = "email"
  labels = {
    email_address = var.alert_config.notification_email
  }
  force_delete = false
}

resource "google_monitoring_alert_policy" "alert_policy_all" {
  count                 = var.alert_config.enabled ? 1 : 0
  project               = var.monitoring_project_id
  combiner              = "OR"
  display_name          = "Endpoint Uptime Check - Missing Uptimes"
  enabled               = var.alert_config.enabled
  notification_channels = [google_monitoring_notification_channel.email[0].id]
  conditions {
    display_name = "Missing Uptimes"
    condition_absent {
      filter   = "resource.type = \"global\" AND metric.type = \"${google_monitoring_metric_descriptor.custom_metrics["endpoint-uptime"].type}\""
      duration = "120s"
    }
  }
}

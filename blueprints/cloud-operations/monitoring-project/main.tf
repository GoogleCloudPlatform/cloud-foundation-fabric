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
  monitoring_project_name = var.project_id
  notification_channels   = var.create_notification_channels ? ["email"] : []
}

module "project" {
  source          = "../../../modules/project"
  name            = local.monitoring_project_name
  parent          = var.parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com"
  ]
}

resource "google_monitoring_notification_channel" "email" {
  count        = var.create_notification_channels && var.notification_email != null ? 1 : 0
  project      = module.project.project_id
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "cpu_utilization" {
  count        = var.create_alert_policies ? 1 : 0
  project      = module.project.project_id
  display_name = "High CPU Utilization"
  combiner     = "OR"
  conditions {
    display_name = "VM Instance - CPU utilization"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.create_notification_channels && var.notification_email != null ? [
    google_monitoring_notification_channel.email[0].name
  ] : []

  documentation {
    content   = "This alert fires when CPU utilization exceeds 80% for more than 1 minute."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "disk_usage" {
  count        = var.create_alert_policies ? 1 : 0
  project      = module.project.project_id
  display_name = "High Disk Usage"
  combiner     = "OR"
  conditions {
    display_name = "VM Instance - Disk usage"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 90
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.create_notification_channels && var.notification_email != null ? [
    google_monitoring_notification_channel.email[0].name
  ] : []

  documentation {
    content   = "This alert fires when disk usage exceeds 90% for more than 5 minutes."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_dashboard" "vm_dashboard" {
  count        = var.create_dashboards ? 1 : 0
  project      = module.project.project_id
  dashboard_json = <<EOF
{
  "displayName": "VM Instances Overview",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "plotType": "LINE",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": [
                      "resource.label.\"instance_name\""
                    ]
                  }
                }
              }
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Memory Usage",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "plotType": "LINE",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/memory/percent_used\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": [
                      "resource.label.\"instance_name\""
                    ]
                  }
                }
              }
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Disk Usage",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "plotType": "LINE",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": [
                      "resource.label.\"instance_name\""
                    ]
                  }
                }
              }
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Network Traffic",
        "xyChart": {
          "chartOptions": {
            "mode": "COLOR"
          },
          "dataSets": [
            {
              "plotType": "LINE",
              "targetAxis": "Y1",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/network/received_bytes_count\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "groupByFields": [
                      "resource.label.\"instance_name\""
                    ]
                  }
                },
                "unitOverride": "By"
              }
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      }
    ]
  }
}
EOF
}
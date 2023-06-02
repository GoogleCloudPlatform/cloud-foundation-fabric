/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description VPN monitoring alerts.

resource "google_monitoring_alert_policy" "vpn_tunnel_established" {
  count = (var.vpn_onprem_primary_config != null && var.alert_config.vpn_tunnel_established != null) ? 1 : 0

  project               = module.landing-project.project_id
  display_name          = "VPN Tunnel Established"
  enabled               = var.alert_config.vpn_tunnel_established.enabled
  notification_channels = var.alert_config.vpn_tunnel_established.notification_channels
  user_labels           = var.alert_config.vpn_tunnel_established.user_labels
  combiner              = "OR"

  conditions {
    display_name = "VPN Tunnel Established"

    condition_monitoring_query_language {
      query = join("", [
        "fetch vpn_gateway",
        "| metric vpn.googleapis.com/tunnel_established",
        "| group_by 5m, [value_tunnel_established_max: max(value.tunnel_established)]",
        "| every 5m",
        "| condition val() < 1 '1'",
      ])

      duration = var.alert_config.vpn_tunnel_established.duration

      trigger {
        count = "1"
      }
    }
  }

  dynamic "alert_strategy" {
    for_each = var.alert_config.vpn_tunnel_established.auto_close != null ? [1] : []

    content {
      auto_close = var.alert_config.vpn_tunnel_established.auto_close
    }
  }
}

# https://cloud.google.com/network-connectivity/docs/vpn/how-to/viewing-logs-metrics#define-bandwidth-alerts
resource "google_monitoring_alert_policy" "vpn_tunnel_bandwidth" {
  count = (var.vpn_onprem_primary_config != null && var.alert_config.vpn_tunnel_bandwidth != null) ? 1 : 0

  project               = module.landing-project.project_id
  display_name          = "VPN Tunnel Bandwidth usage"
  enabled               = var.alert_config.vpn_tunnel_bandwidth.enabled
  notification_channels = var.alert_config.vpn_tunnel_bandwidth.notification_channels
  user_labels           = var.alert_config.vpn_tunnel_bandwidth.user_labels
  combiner              = "OR"

  conditions {
    display_name = "VPN Tunnel Bandwidth usage"

    condition_monitoring_query_language {
      query = join("", [
        "fetch vpn_gateway",
        "| { metric vpn.googleapis.com/network/sent_bytes_count",
        "; metric vpn.googleapis.com/network/received_bytes_count }",
        "| align rate (1m)",
        "| group_by [metric.tunnel_name]",
        "| outer_join 0,0",
        "| value val(0) + val(1)",
        "| condition val() > ${var.alert_config.vpn_tunnel_bandwidth.threshold_mbys} \"MBy/s\"",
      ])

      duration = var.alert_config.vpn_tunnel_bandwidth.duration

      trigger {
        count = "1"
      }
    }
  }

  dynamic "alert_strategy" {
    for_each = var.alert_config.vpn_tunnel_bandwidth.auto_close != null ? [1] : []

    content {
      auto_close = var.alert_config.vpn_tunnel_bandwidth.auto_close
    }
  }
}

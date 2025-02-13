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

# tfdoc:file:description Backend service resources.

locals {
  group_ids = merge(
    {
      for k, v in google_compute_instance_group.default : k => v.id
    },
    {
      for k, v in google_compute_network_endpoint_group.default : k => v.id
    },
    {
      for k, v in google_compute_region_network_endpoint_group.psc : k => v.id
    },
    {
      for k, v in google_compute_region_network_endpoint_group.internet : k => v.id
    }

  )
}

resource "google_compute_region_backend_service" "default" {
  provider                        = google-beta
  project                         = var.project_id
  region                          = var.region
  name                            = var.name
  description                     = var.description
  affinity_cookie_ttl_sec         = var.backend_service_config.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = var.backend_service_config.connection_draining_timeout_sec
  health_checks                   = [local.health_check]
  load_balancing_scheme           = "INTERNAL_MANAGED"
  port_name                       = var.backend_service_config.port_name # defaults to http, not for NEGs
  protocol                        = "TCP"
  session_affinity                = var.backend_service_config.session_affinity
  timeout_sec                     = var.backend_service_config.timeout_sec

  dynamic "backend" {
    for_each = { for b in coalesce(var.backend_service_config.backends, []) : b.group => b }
    content {
      group           = lookup(local.group_ids, backend.key, backend.key)
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      description     = backend.value.description
      failover        = backend.value.failover
      max_connections = try(
        backend.value.max_connections.per_group, null
      )
      max_connections_per_endpoint = try(
        backend.value.max_connections.per_endpoint, null
      )
      max_connections_per_instance = try(
        backend.value.max_connections.per_instance, null
      )
      max_utilization = backend.value.max_utilization
    }
  }

  dynamic "connection_tracking_policy" {
    for_each = var.backend_service_config.connection_tracking == null ? [] : [""]
    content {
      connection_persistence_on_unhealthy_backends = (
        ar.backend_service_config.connection_tracking.persist_conn_on_unhealthy != null
        ? ar.backend_service_config.connection_tracking.persist_conn_on_unhealthy
        : null
      )
      idle_timeout_sec = var.backend_service_config.connection_tracking.idle_timeout_sec
      tracking_mode    = try(local.bs_conntrack.track_per_session ? "PER_SESSION" : "PER_CONNECTION", null)
    }
  }

  dynamic "failover_policy" {
    for_each = var.backend_service_config.failover_config == null ? [] : [""]
    content {
      disable_connection_drain_on_failover = var.backend_service_config.failover_config.disable_conn_drain
      drop_traffic_if_unhealthy            = var.backend_service_config.failover_config.drop_traffic_if_unhealthy
      failover_ratio                       = var.backend_service_config.failover_config.ratio
    }
  }

  dynamic "log_config" {
    for_each = var.backend_service_config.log_sample_rate == null ? [] : [""]
    content {
      enable      = true
      sample_rate = var.backend_service_config.log_sample_rate
    }
  }

}

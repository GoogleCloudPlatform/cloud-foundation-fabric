/**
 * Copyright 2026 Google LLC
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
    }
  )
}

locals {
  lb_policy_backends = {
    for k, v in var.backend_service_configs :
    k => v if try(v.service_lb_policy_config.enable, false)
  }
}

resource "google_network_services_service_lb_policies" "default" {
  for_each = local.lb_policy_backends
  provider = google-beta
  project  = local.project_id

  name                     = coalesce(each.value.name, "${var.name}-${each.key}")
  location                 = "global"
  description              = each.value.description
  load_balancing_algorithm = each.value.service_lb_policy_config.load_balancing_algorithm

  dynamic "auto_capacity_drain" {
    for_each = each.value.service_lb_policy_config.auto_capacity_drain == null ? [] : [""]
    content {
      enable = each.value.service_lb_policy_config.auto_capacity_drain
    }
  }

  dynamic "failover_config" {
    for_each = each.value.service_lb_policy_config.failover_health_threshold == null ? [] : [""]
    content {
      failover_health_threshold = each.value.service_lb_policy_config.failover_health_threshold
    }
  }
}

resource "google_compute_backend_service" "default" {
  for_each                        = var.backend_service_configs
  provider                        = google-beta
  project                         = local.project_id
  name                            = coalesce(each.value.name, "${var.name}-${each.key}")
  description                     = each.value.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks                   = [local.health_check]
  load_balancing_scheme           = "INTERNAL_MANAGED"
  port_name                       = each.value.port_name
  protocol                        = "TCP"
  session_affinity                = each.value.session_affinity
  timeout_sec                     = each.value.timeout_sec
  service_lb_policy = (
    try(each.value.service_lb_policy_config.enable, false)
    ? google_network_services_service_lb_policies.default[each.key].id
    : null
  )

  dynamic "backend" {
    for_each = { for b in coalesce(each.value.backends, []) : b.group => b }
    content {
      group           = lookup(local.group_ids, backend.key, backend.key)
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      description     = backend.value.description
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

  dynamic "log_config" {
    for_each = each.value.log_config == null ? [] : [""]
    content {
      enable          = each.value.log_config.enable
      sample_rate     = each.value.log_config.sample_rate
      optional_mode   = each.value.log_config.optional_mode
      optional_fields = each.value.log_config.optional_fields
    }
  }
}

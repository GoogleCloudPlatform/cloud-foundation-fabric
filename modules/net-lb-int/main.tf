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


locals {
  bs_conntrack = var.backend_service_config.connection_tracking
  bs_failover  = var.backend_service_config.failover_config
  forwarding_rule_names = {
    for k, v in var.forwarding_rules_config :
    k => k == "" ? var.name : "${var.name}-${k}"
  }
  health_check = (
    var.health_check != null
    ? var.health_check
    : google_compute_health_check.default[0].self_link
  )
  _service_attachments = (
    var.service_attachments == null ? {} : var.service_attachments
  )
  service_attachments = {
    for k, v in local._service_attachments :
    k => v if lookup(var.forwarding_rules_config, k, null) != null
  }
}

moved {
  from = google_compute_forwarding_rule.forwarding_rules
  to   = google_compute_forwarding_rule.default
}

resource "google_compute_forwarding_rule" "default" {
  for_each    = var.forwarding_rules_config
  provider    = google-beta
  project     = var.project_id
  name        = coalesce(each.value.name, local.forwarding_rule_names[each.key])
  region      = var.region
  description = each.value.description
  ip_address  = each.value.address
  ip_protocol = each.value.protocol
  ip_version  = each.value.ip_version
  backend_service = (
    google_compute_region_backend_service.default.self_link
  )
  load_balancing_scheme = "INTERNAL"
  network               = var.vpc_config.network
  ports                 = each.value.ports # "nnnnn" or "nnnnn,nnnnn,nnnnn" max 5
  subnetwork            = var.vpc_config.subnetwork
  allow_global_access   = each.value.global_access
  labels                = var.labels
  all_ports             = each.value.ports == null ? true : null
  service_label         = var.service_label
  # is_mirroring_collector = false
}

resource "google_compute_region_backend_service" "default" {
  provider                        = google-beta
  project                         = var.project_id
  region                          = var.region
  name                            = coalesce(var.backend_service_config.name, var.name)
  description                     = var.description
  load_balancing_scheme           = "INTERNAL"
  protocol                        = var.backend_service_config.protocol
  network                         = var.vpc_config.network
  health_checks                   = [local.health_check]
  connection_draining_timeout_sec = var.backend_service_config.connection_draining_timeout_sec
  session_affinity                = var.backend_service_config.session_affinity
  timeout_sec                     = var.backend_service_config.timeout_sec

  iap { enabled = false }

  dynamic "backend" {
    for_each = { for b in var.backends : b.group => b }
    content {
      balancing_mode = "CONNECTION"
      description    = backend.value.description
      failover       = backend.value.failover
      group = try(
        google_compute_instance_group.default[backend.key].id,
        backend.key
      )
    }
  }

  dynamic "connection_tracking_policy" {
    for_each = local.bs_conntrack == null ? [] : [""]
    content {
      connection_persistence_on_unhealthy_backends = (
        local.bs_conntrack.persist_conn_on_unhealthy != null
        ? local.bs_conntrack.persist_conn_on_unhealthy
        : null
      )
      idle_timeout_sec = local.bs_conntrack.idle_timeout_sec
      tracking_mode    = try(local.bs_conntrack.track_per_session ? "PER_SESSION" : "PER_CONNECTION", null)
    }
  }

  dynamic "failover_policy" {
    for_each = local.bs_failover == null ? [] : [""]
    content {
      disable_connection_drain_on_failover = local.bs_failover.disable_conn_drain
      drop_traffic_if_unhealthy            = local.bs_failover.drop_traffic_if_unhealthy
      failover_ratio                       = local.bs_failover.ratio
    }
  }

  dynamic "log_config" {
    for_each = var.backend_service_config.log_sample_rate == null ? [] : [""]
    content {
      enable      = true
      sample_rate = var.backend_service_config.log_sample_rate
    }
  }

  dynamic "subsetting" {
    for_each = var.backend_service_config.enable_subsetting == true ? [""] : []
    content {
      policy = "CONSISTENT_HASH_SUBSETTING"
    }
  }

}

resource "google_compute_service_attachment" "default" {
  for_each       = local.service_attachments
  project        = var.project_id
  region         = var.region
  name           = local.forwarding_rule_names[each.key]
  description    = var.description
  target_service = google_compute_forwarding_rule.default[each.key].id
  nat_subnets    = each.value.nat_subnets
  connection_preference = (
    each.value.automatic_connection ? "ACCEPT_AUTOMATIC" : "ACCEPT_MANUAL"
  )
  consumer_reject_lists = each.value.consumer_reject_lists
  domain_names = (
    each.value.domain_name == null ? null : [each.value.domain_name]
  )
  enable_proxy_protocol = each.value.enable_proxy_protocol
  reconcile_connections = each.value.reconcile_connections
  dynamic "consumer_accept_lists" {
    for_each = each.value.consumer_accept_lists
    iterator = accept
    content {
      project_id_or_num = accept.key
      connection_limit  = accept.value
    }
  }
}

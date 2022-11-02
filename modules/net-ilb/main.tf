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


locals {
  health_check = (
    var.health_check != null
    ? var.health_check
    : try(local.health_check_resource.self_link, null)
  )
  health_check_resource = try(
    google_compute_health_check.http.0,
    google_compute_health_check.https.0,
    google_compute_health_check.tcp.0,
    google_compute_health_check.ssl.0,
    google_compute_health_check.http2.0,
    {}
  )
  health_check_type = try(var.health_check_config.type, null)
}

resource "google_compute_forwarding_rule" "default" {
  provider    = google-beta
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  ip_address  = var.address
  ip_protocol = var.protocol # TCP | UDP
  backend_service = (
    google_compute_region_backend_service.default.self_link
  )
  load_balancing_scheme = "INTERNAL"
  network               = var.network
  ports                 = var.ports # "nnnnn" or "nnnnn,nnnnn,nnnnn" max 5
  subnetwork            = var.subnetwork
  allow_global_access   = var.global_access
  labels                = var.labels
  all_ports             = var.ports == null ? true : null
  service_label         = var.service_label
  # is_mirroring_collector = false
}

resource "google_compute_region_backend_service" "default" {
  provider              = google-beta
  project               = var.project_id
  name                  = var.name
  description           = "Terraform managed."
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  network               = var.network
  health_checks         = [local.health_check]
  protocol              = var.protocol

  session_affinity                = try(var.backend_config.session_affinity, null)
  timeout_sec                     = try(var.backend_config.timeout_sec, null)
  connection_draining_timeout_sec = try(var.backend_config.connection_draining_timeout_sec, null)

  dynamic "backend" {
    for_each = { for b in var.backends : b.group => b }
    iterator = backend
    content {
      balancing_mode = backend.value.balancing_mode
      description    = "Terraform managed."
      failover       = backend.value.failover
      group          = backend.key
    }
  }

  dynamic "failover_policy" {
    for_each = var.failover_config == null ? [] : [var.failover_config]
    iterator = config
    content {
      disable_connection_drain_on_failover = config.value.disable_connection_drain
      drop_traffic_if_unhealthy            = config.value.drop_traffic_if_unhealthy
      failover_ratio                       = config.value.ratio
    }
  }

}

resource "google_compute_instance_group" "unmanaged" {
  for_each    = var.group_configs
  project     = var.project_id
  zone        = each.value.zone
  name        = each.key
  description = "Terraform-managed."
  instances   = each.value.instances
  dynamic "named_port" {
    for_each = each.value.named_ports != null ? each.value.named_ports : {}
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
}

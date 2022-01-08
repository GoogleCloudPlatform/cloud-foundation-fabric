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
  provider              = google-beta
  project               = var.project_id
  name                  = var.name
  description           = "Terraform managed."
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  network               = var.network
  subnetwork            = var.subnetwork
  ip_address            = var.address
  ip_protocol           = var.protocol # TCP | UDP
  ports                 = var.ports    # "nnnnn" or "nnnnn,nnnnn,nnnnn" max 5
  service_label         = var.service_label
  all_ports             = var.ports == null ? true : null
  allow_global_access   = var.global_access
  backend_service       = google_compute_region_backend_service.default.self_link
  # is_mirroring_collector = false
  labels = var.labels
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

resource "google_compute_health_check" "http" {
  provider = google-beta
  count = (
    var.health_check == null && local.health_check_type == "http" ? 1 : 0
  )
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  http_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "https" {
  provider = google-beta
  count = (
    var.health_check == null && local.health_check_type == "https" ? 1 : 0
  )
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  https_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "tcp" {
  provider = google-beta
  count = (
    var.health_check == null && local.health_check_type == "tcp" ? 1 : 0
  )
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  tcp_health_check {
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request            = try(var.health_check_config.check.request, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "ssl" {
  provider = google-beta
  count = (
    var.health_check == null && local.health_check_type == "ssl" ? 1 : 0
  )
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  ssl_health_check {
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request            = try(var.health_check_config.check.request, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}

resource "google_compute_health_check" "http2" {
  provider = google-beta
  count = (
    var.health_check == null && local.health_check_type == "http2" ? 1 : 0
  )
  project     = var.project_id
  name        = var.name
  description = "Terraform managed."

  check_interval_sec  = try(var.health_check_config.config.check_interval_sec, null)
  healthy_threshold   = try(var.health_check_config.config.healthy_threshold, null)
  timeout_sec         = try(var.health_check_config.config.timeout_sec, null)
  unhealthy_threshold = try(var.health_check_config.config.unhealthy_threshold, null)

  http2_health_check {
    host               = try(var.health_check_config.check.host, null)
    port               = try(var.health_check_config.check.port, null)
    port_name          = try(var.health_check_config.check.port_name, null)
    port_specification = try(var.health_check_config.check.port_specification, null)
    proxy_header       = try(var.health_check_config.check.proxy_header, null)
    request_path       = try(var.health_check_config.check.request_path, null)
    response           = try(var.health_check_config.check.response, null)
  }

  dynamic "log_config" {
    for_each = try(var.health_check_config.logging, false) ? [""] : []
    content {
      enable = true
    }
  }
}


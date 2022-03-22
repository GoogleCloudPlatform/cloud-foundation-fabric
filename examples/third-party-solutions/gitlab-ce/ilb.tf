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

# tfdoc:file:description Internal load balancer resources.

resource "google_compute_health_check" "ilb" {
  provider = google-beta
  project  = var.project_id
  name     = "${var.prefix}-http"
  http_health_check {
    request_path = "/"
  }
  log_config {
    enable = true
  }
}

resource "google_compute_address" "ilb" {
  project      = var.project_id
  name         = var.prefix
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = var.network_config.subnet_self_link
}

resource "google_compute_region_backend_service" "ilb" {
  provider              = google-beta
  project               = var.project_id
  name                  = var.prefix
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  network               = var.network_config.vpc_self_link
  health_checks         = [google_compute_health_check.ilb.self_link]
  protocol              = "TCP"
  dynamic "backend" {
    for_each = google_compute_instance_group_manager.default
    content {
      balancing_mode = "CONNECTION"
      group          = backend.value.instance_group
    }
  }
}

resource "google_compute_forwarding_rule" "ilb" {
  project               = var.project_id
  name                  = var.prefix
  load_balancing_scheme = "INTERNAL"
  region                = var.region
  network               = var.network_config.vpc_self_link
  subnetwork            = var.network_config.subnet_self_link
  ip_address            = google_compute_address.ilb.address
  ip_protocol           = "TCP"
  ports                 = [80, 443]
  allow_global_access   = true
  backend_service       = google_compute_region_backend_service.ilb.self_link
  labels                = {}
}

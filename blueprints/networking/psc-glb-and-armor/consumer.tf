// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

locals {
  consumer_apis = ["iam.googleapis.com", "compute.googleapis.com"]
}

data "google_project" "consumer" {
  project_id = var.consumer_project_id
}

resource "google_project_service" "consumer" {
  for_each = toset(local.consumer_apis)
  project  = data.google_project.consumer.project_id
  service  = each.key

  disable_on_destroy = false
}

resource "google_compute_region_network_endpoint_group" "psc_neg" {
  name                  = "psc-neg"
  region                = var.region
  project               = var.consumer_project_id
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = google_compute_service_attachment.psc_ilb_service_attachment.self_link

  network    = "default"
  subnetwork = "default"
}

resource "google_compute_global_forwarding_rule" "default" {
  project               = var.consumer_project_id
  name                  = "global-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
}

output "lb_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}

resource "google_compute_target_http_proxy" "default" {
  project     = var.consumer_project_id
  name        = "target-proxy"
  description = "a description"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  project         = var.consumer_project_id
  name            = "url-map-target-proxy"
  description     = "A simple URL Map, routing all traffic to the PSC NEG"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

resource "google_compute_security_policy" "policy" {
  provider = google-beta
  project  = var.consumer_project_id
  name     = "ddos-protection"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
  depends_on = [
    google_project_service.consumer
  ]
}

resource "google_compute_backend_service" "default" {
  provider              = google-beta
  project               = var.consumer_project_id
  name                  = "backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  security_policy       = google_compute_security_policy.policy.id
  backend {
    group           = google_compute_region_network_endpoint_group.psc_neg.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
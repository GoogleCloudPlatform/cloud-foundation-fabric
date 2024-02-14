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

module "consumer_project" {
  source         = "../../../modules/project"
  name           = var.consumer_project_id
  project_create = var.project_create
  services = [
    "iam.googleapis.com",
    "compute.googleapis.com",
  ]
}

module "producer_a_project" {
  source         = "./modules/producer"
  producer_project_id = var.producer_a_project_id
}

module "producer_b_project" {
  source         = "./modules/producer"
  producer_project_id = var.producer_b_project_id
}

resource "google_compute_region_network_endpoint_group" "psc_neg_a" {
  name                  = "psc-neg-a"
  region                = var.region
  project               = module.consumer_project.project_id
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.producer_a_project.psc_ilb_service_attachment.self_link

  network    = "default"
  subnetwork = "default"
}

resource "google_compute_region_network_endpoint_group" "psc_neg_b" {
  name                  = "psc-neg-b"
  region                = var.region
  project               = module.consumer_project.project_id
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.producer_b_project.psc_ilb_service_attachment.self_link

  network    = "default"
  subnetwork = "default"
}

resource "google_compute_global_forwarding_rule" "default" {
  project               = module.consumer_project.project_id
  name                  = "global-rule"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
}

resource "google_compute_target_http_proxy" "default" {
  project     = module.consumer_project.project_id
  name        = "target-proxy"
  description = "a description"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  project         = module.consumer_project.project_id
  name            = "url-map-target-proxy"
  description     = "A simple URL Map, routing all traffic to the PSC NEG"
  default_service = google_compute_backend_service.backend-a.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.backend-a.id

    path_rule {
      paths   = ["/b/*"]
      service = google_compute_backend_service.backend-b.id
    }

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.backend-a.id
    }
  }
}

resource "google_compute_security_policy" "policy" {
  provider = google-beta
  project  = module.consumer_project.project_id
  name     = "ddos-protection"
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

resource "google_compute_backend_service" "backend-a" {
  provider              = google-beta
  project               = module.consumer_project.project_id
  name                  = "backend-a"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group           = google_compute_region_network_endpoint_group.psc_neg_a.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_backend_service" "backend-b" {
  provider              = google-beta
  project               = module.consumer_project.project_id
  name                  = "backend-b"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  backend {
    group           = google_compute_region_network_endpoint_group.psc_neg_b.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
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

module "producer_project" {
  source         = "../../../modules/project"
  name           = var.producer_project_id
  project_create = var.project_create
  services = [
    "iam.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com",
  ]
}

resource "google_service_account" "app" {
  project      = module.producer_project.project_id
  account_id   = "example-app"
  display_name = "Example App Service Account"
}

resource "google_cloud_run_service" "app" {
  name     = "example-app"
  location = var.region
  project  = module.producer_project.project_id

  template {
    spec {
      containers {
        image = "kennethreitz/httpbin:latest"
        ports {
          container_port = 80
        }
      }
      service_account_name = google_service_account.app.email
    }
  }

  autogenerate_revision_name = true
  traffic {
    percent         = 100
    latest_revision = true
  }
  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }
}

resource "google_compute_region_network_endpoint_group" "neg" {
  name                  = "example-app-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = module.producer_project.project_id
  cloud_run {
    service = google_cloud_run_service.app.name
  }
}

resource "google_compute_forwarding_rule" "psc_ilb_target_service" {
  name    = "producer-forwarding-rule"
  region  = var.region
  project = module.producer_project.project_id

  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  allow_global_access   = true
  target                = google_compute_region_target_https_proxy.default.id

  network    = google_compute_network.psc_ilb_network.name
  subnetwork = google_compute_subnetwork.ilb_subnetwork.name
}

resource "google_compute_region_target_https_proxy" "default" {
  name             = "l7-ilb-target-http-proxy"
  provider         = google-beta
  region           = var.region
  project          = module.producer_project.project_id
  url_map          = google_compute_region_url_map.default.id
  ssl_certificates = [google_compute_region_ssl_certificate.default.id]
}

resource "google_compute_region_ssl_certificate" "default" {
  region      = var.region
  project     = module.producer_project.project_id
  name        = "my-certificate"
  private_key = tls_private_key.example.private_key_pem
  certificate = tls_self_signed_cert.example.cert_pem
}

resource "google_compute_region_url_map" "default" {
  name            = "l7-ilb-regional-url-map"
  provider        = google-beta
  region          = var.region
  project         = module.producer_project.project_id
  default_service = google_compute_region_backend_service.producer_service_backend.id
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "app.example.com"
    organization = "Org"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
resource "google_compute_region_backend_service" "producer_service_backend" {
  name                  = "producer-service"
  region                = var.region
  project               = module.producer_project.project_id
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group           = google_compute_region_network_endpoint_group.neg.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_network" "psc_ilb_network" {
  name                    = "psc-ilb-network"
  auto_create_subnetworks = false
  project                 = module.producer_project.project_id
}

resource "google_compute_subnetwork" "ilb_subnetwork" {
  name    = "ilb-subnetwork"
  region  = var.region
  project = module.producer_project.project_id

  network       = google_compute_network.psc_ilb_network.id
  ip_cidr_range = "10.0.0.0/16"
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "psc_private_subnetwork" {
  name    = "psc-private-subnetwork"
  region  = var.region
  project = module.producer_project.project_id

  network       = google_compute_network.psc_ilb_network.id
  ip_cidr_range = "10.3.0.0/16"
  purpose       = "PRIVATE"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "psc_ilb_nat" {
  name    = "psc-ilb-nat"
  region  = var.region
  project = module.producer_project.project_id

  network       = google_compute_network.psc_ilb_network.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = "10.1.0.0/16"
}

resource "google_compute_subnetwork" "vms" {
  name    = "vms"
  region  = var.region
  project = module.producer_project.project_id

  network       = google_compute_network.psc_ilb_network.id
  ip_cidr_range = "10.4.0.0/16"
}

resource "google_compute_service_attachment" "psc_ilb_service_attachment" {
  name        = "my-psc-ilb"
  region      = var.region
  project     = module.producer_project.project_id
  description = "A service attachment configured with Terraform"

  enable_proxy_protocol = false
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [google_compute_subnetwork.psc_ilb_nat.id]
  target_service        = google_compute_forwarding_rule.psc_ilb_target_service.id
}

resource "google_service_account" "noop" {
  project      = module.producer_project.project_id
  account_id   = "noop-sa"
  display_name = "Service Account for NOOP VM"
}

resource "google_compute_instance" "noop-vm" {
  project      = module.producer_project.project_id
  name         = "noop-ilb-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.psc_ilb_network.id
    subnetwork = google_compute_subnetwork.vms.id
  }
  service_account {
    email  = google_service_account.noop.email
    scopes = []
  }
}
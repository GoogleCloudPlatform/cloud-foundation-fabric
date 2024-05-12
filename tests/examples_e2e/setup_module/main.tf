# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  prefix = "${var.prefix}-${var.timestamp}${var.suffix}"
  jit_services = [
    "storage.googleapis.com",  # no permissions granted by default
    "sqladmin.googleapis.com", # roles/cloudsql.serviceAgent
  ]
  services = [
    # trimmed down list of services, to be extended as needed
    "apigee.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataproc.googleapis.com",
    "dns.googleapis.com",
    "eventarc.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "vpcaccess.googleapis.com",
  ]
}

resource "google_folder" "folder" {
  display_name = "E2E Tests ${var.timestamp}-${var.suffix}"
  parent       = var.parent
}

resource "google_project" "project" {
  name            = "${local.prefix}-prj"
  billing_account = var.billing_account
  folder_id       = google_folder.folder.id
  project_id      = "${local.prefix}-prj"
}

resource "google_project_service" "project_service" {
  for_each                   = toset(local.services)
  service                    = each.value
  project                    = google_project.project.project_id
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_storage_bucket" "bucket" {
  location      = var.region
  name          = "${local.prefix}-bucket"
  project       = google_project.project.project_id
  force_destroy = true
  depends_on    = [google_project_service.project_service]
}

resource "google_compute_network" "network" {
  name                    = "e2e-test"
  project                 = google_project.project.project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.project_service]
}

resource "google_compute_subnetwork" "subnetwork" {
  ip_cidr_range            = "10.0.16.0/24"
  name                     = "e2e-test-1"
  network                  = google_compute_network.network.name
  project                  = google_project.project.project_id
  private_ip_google_access = true
  region                   = var.region
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "100.68.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "100.71.1.0/24"
  }
}

resource "google_compute_subnetwork" "proxy_only_global" {
  project       = google_project.project.project_id
  network       = google_compute_network.network.name
  name          = "proxy-global"
  region        = var.region
  ip_cidr_range = "10.0.17.0/24"
  purpose       = "GLOBAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "proxy_only_regional" {
  project       = google_project.project.project_id
  network       = google_compute_network.network.name
  name          = "proxy-regional"
  region        = var.region
  ip_cidr_range = "10.0.18.0/24"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_subnetwork" "psc" {
  project       = google_project.project.project_id
  network       = google_compute_network.network.name
  name          = "psc-regional"
  region        = var.region
  ip_cidr_range = "10.0.19.0/24"
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

### PSA ###

resource "google_compute_global_address" "psa_ranges" {
  project       = google_project.project.project_id
  network       = google_compute_network.network.id
  name          = "psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.0.20.0"
  prefix_length = 22
}

resource "google_service_networking_connection" "psa_connection" {
  network                 = google_compute_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_ranges.name]
  deletion_policy         = "ABANDON"
}

### END OF PSA

resource "google_service_account" "service_account" {
  account_id = "e2e-service-account"
  project    = google_project.project.project_id
  depends_on = [google_project_service.project_service]
}

resource "google_kms_key_ring" "keyring" {
  name       = "keyring"
  project    = google_project.project.project_id
  location   = var.region
  depends_on = [google_project_service.project_service]
}

resource "google_kms_crypto_key" "key" {
  name            = "crypto-key-example"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"
}

resource "google_project_service_identity" "jit_si" {
  for_each   = toset(local.jit_services)
  provider   = google-beta
  project    = google_project.project.project_id
  service    = each.value
  depends_on = [google_project_service.project_service]
}

resource "google_project_iam_binding" "cloudsql_agent" {
  members    = ["serviceAccount:service-${google_project.project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com"]
  project    = google_project.project.project_id
  role       = "roles/cloudsql.serviceAgent"
  depends_on = [google_project_service_identity.jit_si]
}

resource "local_file" "terraform_tfvars" {
  filename = "e2e_tests.tfvars"
  content = templatefile("e2e_tests.tfvars.tftpl", {
    bucket             = google_storage_bucket.bucket.name
    billing_account_id = var.billing_account
    folder_id          = google_folder.folder.folder_id
    group_email        = var.group_email
    kms_key_id         = google_kms_crypto_key.key.id
    keyring = {
      name = google_kms_key_ring.keyring.name
    }
    organization_id = var.organization_id
    project_id      = google_project.project.project_id
    project_number  = google_project.project.number
    region          = var.region
    service_account = {
      id        = google_service_account.service_account.id
      email     = google_service_account.service_account.email
      iam_email = "serviceAccount:${google_service_account.service_account.email}"
    }
    subnet = {
      name          = google_compute_subnetwork.subnetwork.name
      region        = google_compute_subnetwork.subnetwork.region
      ip_cidr_range = google_compute_subnetwork.subnetwork.ip_cidr_range
      self_link     = google_compute_subnetwork.subnetwork.self_link
    }
    subnet_psc_1 = {
      name          = google_compute_subnetwork.psc.name
      region        = google_compute_subnetwork.psc.region
      ip_cidr_range = google_compute_subnetwork.psc.ip_cidr_range
      self_link     = google_compute_subnetwork.psc.self_link
    }
    vpc = {
      name      = google_compute_network.network.name
      self_link = google_compute_network.network.self_link
      id        = google_compute_network.network.id
    }
  })
}

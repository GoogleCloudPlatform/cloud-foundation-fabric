/**
 * Copyright 2018 Google LLC
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
  prefix_length      = 22
  address_type       = "INTERNAL"
  porpuse            = "VPC_PEERING"
  datafusion_network = var.network != "" ? var.network : ""
  ip_allocation      = var.network != "" ? "${google_compute_global_address.default.address}/${local.prefix_length}" : ""
  tenant_project_re  = "cloud-datafusion-management-sa@([\\w-]+).iam.gserviceaccount.com"
  tenant_project     = regex(local.tenant_project_re, google_data_fusion_instance.default.service_account)[0]
}

resource "google_compute_global_address" "default" {
  #count         = var.private_instance == true ? 1 : 0
  project       = var.project_id
  name          = "cdf-${var.region}-${var.name}"
  purpose       = local.porpuse
  address_type  = local.address_type
  prefix_length = local.prefix_length
  network       = var.network
}

resource "google_compute_network_peering" "default" {
  count                = var.network_peering == true ? 1 : 0
  name                 = "cdf-${var.region}-${var.name}"
  network              = "projects/${var.project_id}/global/networks/${var.network}"
  peer_network         = "projects/${local.tenant_project}/global/networks/${var.region}-${google_data_fusion_instance.default.name}"
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_firewall" "default" {
  count   = var.network_firewall_rules == true ? 1 : 0
  name    = "${var.name}-allow-ssh"
  project = var.project_id
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.ip_allocation]
  target_tags   = ["${var.name}-allow-ssh"]
}

resource "google_data_fusion_instance" "default" {
  provider                      = google-beta
  project                       = var.project_id
  name                          = var.name
  type                          = var.type
  description                   = var.description
  labels                        = var.labels
  region                        = var.region
  private_instance              = var.private_instance
  enable_stackdriver_logging    = var.enable_stackdriver_logging
  enable_stackdriver_monitoring = var.enable_stackdriver_monitoring
  network_config {
    network       = local.datafusion_network
    ip_allocation = local.ip_allocation
  }
}


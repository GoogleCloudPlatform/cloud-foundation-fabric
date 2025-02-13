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
  network_interfaces = [
    {
      addresses           = null
      name                = "ext"
      nat                 = false
      enable_masquerading = true
      network             = module.ext-vpc.self_link
      routes              = [var.ip_ranges.ext, "0.0.0.0/0"]
      subnetwork          = module.ext-vpc.subnet_self_links["${var.region}/ext"]
    },
    {
      addresses  = null
      name       = "hub"
      nat        = false
      network    = module.hub-vpc.self_link
      routes     = [var.ip_ranges.int]
      subnetwork = module.hub-vpc.subnet_self_links["${var.region}/hub-nva"]
    }
  ]
}

module "cos-nva" {
  source               = "../../../modules/cloud-config-container/simple-nva"
  enable_health_checks = true
  network_interfaces   = local.network_interfaces
}

module "nva-a" {
  source             = "../../../modules/compute-vm"
  project_id         = module.project.project_id
  zone               = "${var.region}-a"
  name               = "cos-nva-a"
  network_interfaces = local.network_interfaces
  can_ip_forward     = true
  instance_type      = "e2-micro"
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    user-data              = module.cos-nva.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["nva", "ssh"]
}

module "nva-b" {
  source             = "../../../modules/compute-vm"
  project_id         = module.project.project_id
  zone               = "${var.region}-b"
  name               = "cos-nva-b"
  network_interfaces = local.network_interfaces
  can_ip_forward     = true
  instance_type      = "e2-micro"
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    user-data              = module.cos-nva.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["nva", "ssh"]
}

resource "google_compute_instance_group" "nva-a" {
  name        = "nva-ig-a"
  description = "NVA instance group for the primary region, zone a."
  zone        = "${var.region}-a"
  project     = module.project.project_id
  network     = module.ext-vpc.self_link
  instances = toset([
    module.nva-a.self_link,
  ])
}

resource "google_compute_instance_group" "nva-b" {
  name        = "nva-ig-b"
  description = "NVA instance group for the primary region, zone b."
  zone        = "${var.region}-b"
  project     = module.project.project_id
  network     = module.ext-vpc.self_link
  instances = toset([
    module.nva-b.self_link,
  ])
}

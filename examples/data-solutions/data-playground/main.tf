# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
#                                   Project                                   #
###############################################################################

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  services = [
    "stackdriver.googleapis.com",
    "compute.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "servicenetworking.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "dataflow.googleapis.com",
    "notebooks.googleapis.com",
    "composer.googleapis.com"
  ]
}

###############################################################################
#                                Networking                                   #
###############################################################################

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = var.vpc_name
  subnets = [
    {
      ip_cidr_range      = var.vpc_ip_cidr_range
      name               = var.vpc_subnet_name
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "vpc-firewall" {
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.project.project_id
  network      = module.vpc.name
  admin_ranges = [var.vpc_ip_cidr_range]
}

###############################################################################
#                                GCS                                          #
###############################################################################

module "base-gcs-bucket" {
  source     = "../../../modules/gcs"
  project_id = module.project.project_id
  prefix     = module.project.project_id
  name       = "base"
}

###############################################################################
#                         Vertex AI Notebook                                   #
###############################################################################

resource "google_notebooks_instance" "playground" {
  name         = "data-play-notebook"
  location     = format("%s-%s", var.region, "b")
  machine_type = "e2-medium"
  project      = module.project.project_id

  container_image {
    repository = "gcr.io/deeplearning-platform-release/base-cpu"
    tag        = "latest"
  }

  install_gpu_driver = true
  boot_disk_type     = "PD_SSD"
  boot_disk_size_gb  = 110

  no_public_ip    = false
  no_proxy_access = false

  network = module.vpc.network.id
  subnet  = module.vpc.subnets[format("%s/%s", var.region, var.vpc_subnet_name)].id
}

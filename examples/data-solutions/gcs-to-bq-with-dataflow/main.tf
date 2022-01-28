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

locals {
  subnet_name      = module.vpc.subnets["${var.region}/${var.prefix}-subnet-0"].name
  subnet_self_link = module.vpc.subnets["${var.region}/${var.prefix}-subnet-0"].self_link
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  services = [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "dataflow.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
  ]
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range      = var.vpc_subnet_range
      name               = "${var.prefix}-subnet-0"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "vpc-firewall" {
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.project.project_id
  network      = module.vpc.name
  admin_ranges = [var.vpc_subnet_range]
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${var.prefix}-default"
  router_network = module.vpc.name
}

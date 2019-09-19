# Copyright 2019 Google LLC
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
#                          Host and service projects                          #
###############################################################################

# VPC host project

module "project-svpc-host" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.2.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "vpc-host"
  billing_account = var.billing_account_id
  owners          = var.host_owners
  activate_apis   = var.project_services
}

# service projects

module "project-service-data" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.2.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "data"
  billing_account = var.billing_account_id
  activate_apis   = var.project_services
}

module "project-service-gke" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.2.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "gke"
  billing_account = var.billing_account_id
  activate_apis   = var.project_services
}

################################################################################
#                                  Networking                                  #
################################################################################

# VPC

module "net-vpc-host" {
  source           = "terraform-google-modules/network/google"
  version          = "~> 1.2.0"
  project_id       = module.project-svpc-host.project_id
  network_name     = "vpc-host"
  subnets          = var.subnets
  secondary_ranges = var.subnet_secondary_ranges
  routes           = []
}

# VPC firewall

module "net-vpc-firewall" {
  source               = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version              = "1.2.0"
  project_id           = module.project-svpc-host.project_id
  network              = module.net-vpc-host.network_name
  admin_ranges_enabled = true
  admin_ranges = [
    lookup(
      zipmap(module.net-vpc-host.subnets_names, module.net-vpc-host.subnets_ips),
      "networking"
    )
  ]
}

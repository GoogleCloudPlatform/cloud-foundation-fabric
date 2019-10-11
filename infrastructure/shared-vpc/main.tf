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

locals {
  net_gce_users = concat(
    var.owners_gce,
    ["serviceAccount:${module.project-service-gce.cloudsvc_service_account}"]
  )
  net_gke_users = concat(
    var.owners_gke,
    [
      "serviceAccount:${module.project-service-gke.gke_service_account}",
      "serviceAccount:${module.project-service-gke.cloudsvc_service_account}"
    ]
  )
  net_subnet_ips = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_ips
  )
  net_subnet_links = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_self_links
  )
  net_subnet_regions = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_regions
  )
}

###############################################################################
#                          Host and service projects                          #
###############################################################################

# VPC host project

module "project-svpc-host" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.3.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "vpc-host"
  billing_account = var.billing_account_id
  owners          = var.owners_host
  activate_apis   = var.project_services
}

# service projects

module "project-service-gce" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.3.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "gce"
  billing_account = var.billing_account_id
  oslogin         = "true"
  owners          = var.owners_gce
  oslogin_admins  = var.oslogin_admins_gce
  oslogin_users   = var.oslogin_users_gce
  activate_apis   = var.project_services
}

module "project-service-gke" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.3.0"
  parent          = var.root_node
  prefix          = var.prefix
  name            = "gke"
  billing_account = var.billing_account_id
  owners          = var.owners_gke
  activate_apis   = var.project_services
}

################################################################################
#                                  Networking                                  #
################################################################################

# Shared VPC

module "net-vpc-host" {
  source           = "terraform-google-modules/network/google"
  version          = "1.2.0"
  project_id       = module.project-svpc-host.project_id
  network_name     = "vpc-shared"
  shared_vpc_host  = true
  subnets          = var.subnets
  secondary_ranges = var.subnet_secondary_ranges
  routes           = []
}

# Shared VPC firewall

module "net-vpc-firewall" {
  source               = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version              = "1.2.0"
  project_id           = module.project-svpc-host.project_id
  network              = module.net-vpc-host.network_name
  admin_ranges_enabled = true
  admin_ranges         = [lookup(local.net_subnet_ips, "networking")]
}

# Shared VPC access

module "network_fabric-net-svpc-access" {
  # source              = "terraform-google-modules/network/google//modules/fabric-net-svpc-access"
  # version             = "1.3.0"
  source              = "github.com/terraform-google-modules/terraform-google-network//modules/fabric-net-svpc-access?ref=35b92c3848b4e796c57c4cbedc1529b736614389"
  host_project_id     = module.project-svpc-host.project_id
  service_project_num = 2
  service_project_ids = [
    module.project-service-gce.number, module.project-service-gke.number
  ]
  host_subnets = ["gce", "gke"]
  host_subnet_regions = [
    local.net_subnet_regions["gce"], local.net_subnet_regions["gke"]
  ]
  host_subnet_users = {
    gce = join(",", local.net_gce_users)
    gke = join(",", local.net_gke_users)
  }
  host_service_agent_role = true
  host_service_agent_users = [
    "serviceAccount:${module.project-service-gke.gke_service_account}"
  ]
}

################################################################################
#                                     DNS                                      #
################################################################################

module "dns-host-forwarding-zone" {
  source                             = "terraform-google-modules/cloud-dns/google"
  version                            = "2.0.0"
  project_id                         = module.project-svpc-host.project_id
  type                               = "private"
  name                               = "svpc-fabric-example"
  domain                             = "svpc.fabric."
  private_visibility_config_networks = [module.net-vpc-host.network_self_link]
  record_names                       = ["localhost"]
  record_data = [
    {
      rrdatas = "127.0.0.1"
      type    = "A"
    },
  ]
}

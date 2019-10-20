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

# host project

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
  version          = "1.4.0"
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
  version              = "1.4.0"
  project_id           = module.project-svpc-host.project_id
  network              = module.net-vpc-host.network_name
  admin_ranges_enabled = true
  admin_ranges         = compact([lookup(local.net_subnet_ips, "networking", "")])
  custom_rules = {
    ingress-mysql = {
      description          = "Allow incoming connections on the MySQL port from GKE addresses."
      direction            = "INGRESS"
      action               = "allow"
      ranges               = local.net_gke_ip_ranges
      sources              = []
      targets              = ["mysql"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [3306] }]
      extra_attributes     = {}
    }
  }
}

# Shared VPC access

module "net-svpc-access" {
  source              = "terraform-google-modules/network/google//modules/fabric-net-svpc-access"
  version             = "1.4.0"
  host_project_id     = module.project-svpc-host.project_id
  service_project_num = 2
  service_project_ids = [
    module.project-service-gce.project_id, module.project-service-gke.project_id
  ]
  host_subnets = ["gce", "gke"]
  host_subnet_regions = compact([
    lookup(local.net_subnet_regions, "gce", ""),
    lookup(local.net_subnet_regions, "gke", "")
  ])
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

module "host-dns" {
  source                             = "terraform-google-modules/cloud-dns/google"
  version                            = "2.0.0"
  project_id                         = module.project-svpc-host.project_id
  type                               = "private"
  name                               = "svpc-fabric-example"
  domain                             = "svpc.fabric."
  private_visibility_config_networks = [module.net-vpc-host.network_self_link]
  record_names                       = ["localhost"]
  record_data                        = [{ rrdatas = "127.0.0.1", type = "A" }]
}

################################################################################
#                                     KMS                                      #
################################################################################

module "host-kms" {
  source             = "terraform-google-modules/kms/google"
  version            = "1.1.0"
  project_id         = module.project-svpc-host.project_id
  location           = var.kms_keyring_location
  keyring            = var.kms_keyring_name
  keys               = ["mysql"]
  set_decrypters_for = ["mysql"]
  decrypters         = ["serviceAccount:${module.project-service-gce.gce_service_account}"]
  prevent_destroy    = false
}

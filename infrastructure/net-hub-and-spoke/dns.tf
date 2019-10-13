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

##############################################################
#                           DNS Zones                        #
##############################################################

module "hub-private-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 2.0"

  project_id = var.hub_project_id
  type       = "private"
  name       = "${var.private_dns_zone_name}-hub-private"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-hub.network_self_link]
}

module "spoke-1-peering-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 2.0"

  project_id = var.spoke_1_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-1-peering"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-1.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

module "spoke-2-peering-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 2.0"

  project_id = var.spoke_2_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-2-peering"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-2.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

module "hub-forwarding-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "~> 2.0"

  project_id = var.hub_project_id
  type       = "forwarding"
  name       = "${var.forwarding_dns_zone_name}-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  private_visibility_config_networks = [module.vpc-hub.network_self_link]
  target_name_server_addresses       = var.forwarding_zone_server_addresses
}
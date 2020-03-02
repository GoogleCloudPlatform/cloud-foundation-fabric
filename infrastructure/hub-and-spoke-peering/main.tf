# Copyright 2020 Google LLC
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
  hub_subnet_regions         = [for subnet in var.hub_subnets : subnet["subnet_region"]]
  spoke_1_subnet_regions     = [for subnet in var.spoke_1_subnets : subnet["subnet_region"]]
  spoke_2_subnet_regions     = [for subnet in var.spoke_2_subnets : subnet["subnet_region"]]
  hub_subnet_cidr_ranges     = [for subnet in var.hub_subnets : subnet["subnet_ip"]]
  spoke_1_subnet_cidr_ranges = [for subnet in var.spoke_1_subnets : subnet["subnet_ip"]]
  spoke_2_subnet_cidr_ranges = [for subnet in var.spoke_2_subnets : subnet["subnet_ip"]]
  all_subnet_cidrs           = concat(local.hub_subnet_cidr_ranges, local.spoke_1_subnet_cidr_ranges, local.spoke_2_subnet_cidr_ranges)
}

##############################################################
#                              VPCs                          #
##############################################################

module "vpc-hub" {
  source = "../../modules/net-vpc"

  project_id   = var.hub_project_id
  network_name = "hub-network"
  subnets      = var.hub_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-1" {
  source = "../../modules/net-vpc"

  project_id   = var.spoke_1_project_id
  network_name = "spoke-1-network"
  subnets      = var.spoke_1_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-2" {
  source = "../../modules/net-vpc"

  project_id   = var.spoke_2_project_id
  network_name = "spoke-2-network"
  subnets      = var.spoke_2_subnets
  routing_mode = "GLOBAL"
}

##############################################################
#                        Network Peering                     #
##############################################################

module "hub-to-spoke-1-peering" {
  source = "../../modules/net-vpc-peering"

  local_network              = module.vpc-hub.network_self_link
  peer_network               = module.vpc-spoke-1.network_self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false
}

module "hub-to-spoke-2-peering" {
  source = "../../modules/net-vpc-peering"

  local_network              = module.vpc-hub.network_self_link
  peer_network               = module.vpc-spoke-2.network_self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false

  module_depends_on = [module.hub-to-spoke-1-peering.complete]
}

##############################################################
#                           Firewalls                        #
##############################################################

module "firewall-hub" {
  source = "../../modules/net-vpc-firewall"

  project_id           = var.hub_project_id
  network              = module.vpc-hub.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-1" {
  source = "../../modules/net-vpc-firewall"

  project_id           = var.spoke_1_project_id
  network              = module.vpc-spoke-1.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-2" {
  source = "../../modules/net-vpc-firewall"

  project_id           = var.spoke_2_project_id
  network              = module.vpc-spoke-2.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

##############################################################
#                           DNS Zones                        #
##############################################################

module "hub-private-zone" {
  source = "../../modules/dns"

  project_id = var.hub_project_id
  type       = "private"
  name       = "${var.private_dns_zone_name}-hub-private"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-hub.network_self_link]
}

module "hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.hub_project_id
  type       = "forwarding"
  name       = "${var.forwarding_dns_zone_name}-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  private_visibility_config_networks = [module.vpc-hub.network_self_link]
  target_name_server_addresses       = var.forwarding_zone_server_addresses
}

module "spoke-1-peering-zone-to-hub-private-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_1_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-1-peering-to-hub-private"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-1.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

module "spoke-2-peering-zone-to-hub-private-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_2_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-2-peering-to-hub-private"
  domain     = var.private_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-2.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

module "spoke-1-peering-zone-to-hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_1_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-1-peering-to-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-1.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

module "spoke-2-peering-zone-to-hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_2_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-2-peering-to-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  private_visibility_config_networks = [module.vpc-spoke-2.network_self_link]
  target_network                     = module.vpc-hub.network_self_link
}

##############################################################
#                   Inbount DNS Forwarding                   #
##############################################################

# TODO Provide resolver addresses in the output once https://github.com/terraform-providers/terraform-provider-google/issues/3753 resolved.
# For now please refer to the documentation on how to get the compute addresses for the DNS Resolver https://cloud.google.com/dns/zones/#creating_a_dns_policy_that_enables_inbound_dns_forwarding
resource "google_dns_policy" "google_dns_policy" {
  provider = "google-beta"

  project                   = var.hub_project_id
  name                      = "inbound-dns-forwarding-policy"
  enable_inbound_forwarding = true

  networks {
    network_url = module.vpc-hub.network_self_link
  }
}

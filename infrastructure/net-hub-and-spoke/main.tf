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
#                              VPCs                          #
##############################################################

module "vpc-hub" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.hub_project_id
  network_name = "${var.prefix}-hub"
  subnets      = var.hub_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-1" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.spoke_1_project_id
  network_name = "${var.prefix}-spoke-1"
  subnets      = var.spoke_1_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-2" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.spoke_2_project_id
  network_name = "${var.prefix}-spoke-2"
  subnets      = var.spoke_2_subnets
  routing_mode = "GLOBAL"
}

##############################################################
#                           Firewalls                        #
##############################################################

module "firewall-hub" {
  source  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version = "~> 1.2"

  project_id           = var.hub_project_id
  network              = module.vpc-hub.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-1" {
  source  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version = "~> 1.2"

  project_id           = var.spoke_1_project_id
  network              = module.vpc-spoke-1.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-2" {
  source  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version = "~> 1.2"

  project_id           = var.spoke_2_project_id
  network              = module.vpc-spoke-2.network_name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

##############################################################
#                              VPNs                          #
##############################################################

module "vpn-hub-to-spoke-1" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.1"

  project_id               = var.hub_project_id
  network                  = module.vpc-hub.network_name
  region                   = element(local.hub_subnet_regions, 0)
  tunnel_name_prefix       = "hub-to-spoke-1"
  peer_ips                 = [module.vpn-spoke-1-to-hub.gateway_ip]
  bgp_cr_session_range     = ["169.254.0.1/30"]
  bgp_remote_session_range = ["169.254.0.2"]
  peer_asn                 = [var.spoke_1_bgp_asn]
  cr_name                  = local.hub_to_spoke_1_router
}

module "vpn-hub-to-spoke-2" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.1"

  project_id               = var.hub_project_id
  network                  = module.vpc-hub.network_name
  region                   = element(local.hub_subnet_regions, 1)
  tunnel_name_prefix       = "hub-to-spoke-2"
  peer_ips                 = [module.vpn-spoke-2-to-hub.gateway_ip]
  bgp_cr_session_range     = ["169.254.1.1/30"]
  bgp_remote_session_range = ["169.254.1.2"]
  peer_asn                 = [var.spoke_2_bgp_asn]
  cr_name                  = local.hub_to_spoke_2_router
}

module "vpn-spoke-1-to-hub" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.1"

  project_id               = var.spoke_1_project_id
  network                  = module.vpc-spoke-1.network_name
  region                   = element(local.spoke_1_subnet_regions, 0)
  tunnel_name_prefix       = "spoke-1-to-hub"
  shared_secret            = module.vpn-hub-to-spoke-1.ipsec_secret-dynamic[0]
  peer_ips                 = [module.vpn-hub-to-spoke-1.gateway_ip]
  bgp_cr_session_range     = ["169.254.0.2/30"]
  bgp_remote_session_range = ["169.254.0.1"]
  peer_asn                 = [var.hub_bgp_asn]
  cr_name                  = google_compute_router.spoke-1.name
}

module "vpn-spoke-2-to-hub" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.1"

  project_id               = var.spoke_2_project_id
  network                  = module.vpc-spoke-2.network_name
  region                   = element(local.spoke_2_subnet_regions, 0)
  tunnel_name_prefix       = "spoke-2-to-hub"
  shared_secret            = module.vpn-hub-to-spoke-2.ipsec_secret-dynamic[0]
  peer_ips                 = [module.vpn-hub-to-spoke-2.gateway_ip]
  bgp_cr_session_range     = ["169.254.1.2/30"]
  bgp_remote_session_range = ["169.254.1.1"]
  peer_asn                 = [var.hub_bgp_asn]
  cr_name                  = google_compute_router.spoke-2.name
}

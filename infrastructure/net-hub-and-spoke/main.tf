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
  hub_subnet_regions         = [for subnet in var.hub_subnets : subnet["subnet_region"]]
  spoke_1_subnet_regions     = [for subnet in var.spoke_1_subnets : subnet["subnet_region"]]
  spoke_2_subnet_regions     = [for subnet in var.spoke_2_subnets : subnet["subnet_region"]]
  hub_subnet_cidr_ranges     = [for subnet in var.hub_subnets : subnet["subnet_ip"]]
  spoke_1_subnet_cidr_ranges = [for subnet in var.spoke_1_subnets : subnet["subnet_ip"]]
  spoke_2_subnet_cidr_ranges = [for subnet in var.spoke_2_subnets : subnet["subnet_ip"]]
  all_subnet_cidrs           = concat(local.hub_subnet_cidr_ranges, local.spoke_1_subnet_cidr_ranges, local.spoke_2_subnet_cidr_ranges)
  hub_to_spoke_1_router      = var.spoke_to_spoke_route_advertisement ? element(concat(google_compute_router.hub-to-spoke-1-custom.*.name, list("")), 0) : element(concat(google_compute_router.hub-to-spoke-1-default.*.name, list("")), 0)
  hub_to_spoke_2_router      = var.spoke_to_spoke_route_advertisement ? element(concat(google_compute_router.hub-to-spoke-2-custom.*.name, list("")), 0) : element(concat(google_compute_router.hub-to-spoke-2-default.*.name, list("")), 0)
}

##############################################################
#                              VPCs                          #
##############################################################

module "vpc-hub" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.hub_project_id
  network_name = "hub-network"
  subnets      = var.hub_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-1" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.spoke_1_project_id
  network_name = "spoke-1-network"
  subnets      = var.spoke_1_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-2" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.2"

  project_id   = var.spoke_2_project_id
  network_name = "spoke-2-network"
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
#                        Cloud Routers                       #
##############################################################

resource "google_compute_router" "hub-to-spoke-1-custom" {
  count   = var.spoke_to_spoke_route_advertisement ? 1 : 0
  name    = "hub-to-spoke-1-custom"
  region  = element(local.hub_subnet_regions, 0)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn               = var.hub_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    dynamic "advertised_ip_ranges" {
      for_each = toset(local.spoke_2_subnet_cidr_ranges)
      content {
        range = advertised_ip_ranges.value
      }
    }
  }
}

resource "google_compute_router" "hub-to-spoke-2-custom" {
  count   = var.spoke_to_spoke_route_advertisement ? 1 : 0
  name    = "hub-to-spoke-2-custom"
  region  = element(local.hub_subnet_regions, 1)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn               = var.hub_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    dynamic "advertised_ip_ranges" {
      for_each = toset(local.spoke_1_subnet_cidr_ranges)
      content {
        range = advertised_ip_ranges.value
      }
    }
  }
}

resource "google_compute_router" "hub-to-spoke-1-default" {
  count   = var.spoke_to_spoke_route_advertisement ? 0 : 1
  name    = "hub-to-spoke-1-default"
  region  = element(local.hub_subnet_regions, 0)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn = var.hub_bgp_asn
  }
}
resource "google_compute_router" "hub-to-spoke-2-default" {
  count   = var.spoke_to_spoke_route_advertisement ? 0 : 1
  name    = "hub-to-spoke-2-default"
  region  = element(local.hub_subnet_regions, 1)
  network = module.vpc-hub.network_name
  project = var.hub_project_id
  bgp {
    asn = var.hub_bgp_asn
  }
}
resource "google_compute_router" "spoke-1" {
  name    = "spoke-1"
  region  = element(local.spoke_1_subnet_regions, 0)
  network = module.vpc-spoke-1.network_name
  project = var.spoke_1_project_id
  bgp {
    asn = var.spoke_1_bgp_asn
  }
}
resource "google_compute_router" "spoke-2" {
  name    = "spoke-2"
  region  = element(local.spoke_2_subnet_regions, 0)
  network = module.vpc-spoke-2.network_name
  project = var.spoke_2_project_id
  bgp {
    asn = var.spoke_2_bgp_asn
  }
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

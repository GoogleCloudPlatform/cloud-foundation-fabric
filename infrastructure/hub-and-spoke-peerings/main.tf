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
  hub_subnet_cidr_ranges     = {for subnet in keys(var.hub_subnets) : var.hub_subnets[subnet]["ip_cidr_range"] => subnet}
  spoke_1_subnet_cidr_ranges = {for subnet in keys(var.spoke_1_subnets) : var.spoke_1_subnets[subnet]["ip_cidr_range"] => subnet}
  spoke_2_subnet_cidr_ranges = {for subnet in keys(var.spoke_2_subnets) : var.spoke_2_subnets[subnet]["ip_cidr_range"] => subnet}
  custom_routes_to_spokes    = merge(local.spoke_1_subnet_cidr_ranges, local.spoke_2_subnet_cidr_ranges)
  all_subnet_cidrs           = concat(keys(local.hub_subnet_cidr_ranges), keys(local.spoke_1_subnet_cidr_ranges), keys(local.spoke_2_subnet_cidr_ranges), [var.on_prem_cidr_range])
}

##############################################################
#                              VPCs                          #
##############################################################

module "vpc-hub" {
  source = "../../modules/net-vpc"

  project_id   = var.hub_project_id
  name         = "hub-network"
  subnets      = var.hub_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-1" {
  source = "../../modules/net-vpc"

  project_id   = var.spoke_1_project_id
  name         = "spoke-1-network"
  subnets      = var.spoke_1_subnets
  routing_mode = "GLOBAL"
}

module "vpc-spoke-2" {
  source = "../../modules/net-vpc"

  project_id   = var.spoke_2_project_id
  name         = "spoke-2-network"
  subnets      = var.spoke_2_subnets
  routing_mode = "GLOBAL"
}

##############################################################
#                        Network Peering                     #
##############################################################

module "hub-to-spoke-1-peering" {
  source = "../../modules/net-vpc-peering"

  local_network              = module.vpc-hub.self_link
  peer_network               = module.vpc-spoke-1.self_link
  export_local_custom_routes = true
  export_peer_custom_routes  = false
}

module "hub-to-spoke-2-peering" {
  source = "../../modules/net-vpc-peering"

  local_network              = module.vpc-hub.self_link
  peer_network               = module.vpc-spoke-2.self_link
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
  network              = module.vpc-hub.name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-1" {
  source = "../../modules/net-vpc-firewall"

  project_id           = var.spoke_1_project_id
  network              = module.vpc-spoke-1.name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

module "firewall-spoke-2" {
  source = "../../modules/net-vpc-firewall"

  project_id           = var.spoke_2_project_id
  network              = module.vpc-spoke-2.name
  admin_ranges_enabled = true
  admin_ranges         = local.all_subnet_cidrs
}

##############################################################
#                           DNS Zones                        #
##############################################################

module "hub-private-zone" {
  source = "../../modules/dns"

  project_id      = var.hub_project_id
  type            = "private"
  name            = "${var.private_dns_zone_name}-hub-private"
  domain          = var.private_dns_zone_domain
  client_networks = [module.vpc-hub.self_link]
  recordsets = [
    { name = "hub-test-vm", type = "A", ttl = 300, records = module.vm-hub.internal_ips },
    { name = "spoke-1-test-vm", type = "A", ttl = 300, records = module.vm-spoke-1.internal_ips },
    { name = "spoke-2-test-vm", type = "A", ttl = 300, records = module.vm-spoke-2.internal_ips },
  ]
}

module "hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.hub_project_id
  type       = "forwarding"
  name       = "${var.forwarding_dns_zone_name}-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  client_networks = [module.vpc-hub.self_link]
  forwarders      = [module.on-prem-in-a-box.dns_ip_address]
}

module "spoke-1-peering-zone-to-hub-private-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_1_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-1-peering-to-hub-private"
  domain     = var.private_dns_zone_domain

  client_networks = [module.vpc-spoke-1.self_link]
  peer_network    = module.vpc-hub.self_link
}

module "spoke-2-peering-zone-to-hub-private-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_2_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-2-peering-to-hub-private"
  domain     = var.private_dns_zone_domain

  client_networks = [module.vpc-spoke-2.self_link]
  peer_network    = module.vpc-hub.self_link
}

module "spoke-1-peering-zone-to-hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_1_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-1-peering-to-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  client_networks = [module.vpc-spoke-1.self_link]
  peer_network    = module.vpc-hub.self_link
}

module "spoke-2-peering-zone-to-hub-forwarding-zone" {
  source = "../../modules/dns"

  project_id = var.spoke_2_project_id
  type       = "peering"
  name       = "${var.private_dns_zone_name}-spoke-2-peering-to-hub-forwarding"
  domain     = var.forwarding_dns_zone_domain

  client_networks = [module.vpc-spoke-2.self_link]
  peer_network    = module.vpc-hub.self_link
}

##############################################################
#           TESTING: Inbount DNS Forwarding                  #
##############################################################

# TODO Provide resolver addresses in the output once https://github.com/terraform-providers/terraform-provider-google/issues/3753 resolved.
# For now please refer to the documentation on how to get the compute addresses for the DNS Resolver https://cloud.google.com/dns/zones/#creating_a_dns_policy_that_enables_inbound_dns_forwarding
resource "google_dns_policy" "google_dns_policy" {
  provider = google-beta

  project                   = var.hub_project_id
  name                      = "inbound-dns-forwarding-policy"
  enable_inbound_forwarding = true

  networks {
    network_url = module.vpc-hub.self_link
  }
}

###############################################################################
#                            TESTING: Hub test VM                             #
###############################################################################

module "vm-hub" {
  source = "../../modules/compute-vm"

  project_id = var.hub_project_id
  region     = module.vpc-hub.subnet_regions[keys(var.hub_subnets).0]
  zone       = "${module.vpc-hub.subnet_regions[keys(var.hub_subnets).0]}-b"
  name       = "hub-test-vm"
  network_interfaces = [{
    network    = module.vpc-hub.self_link
    subnetwork = module.vpc-hub.subnet_self_links[keys(var.hub_subnets).0],
    nat        = false,
    addresses  = null
  }]
  instance_count = 1
}

###############################################################################
#                             TESTING: Spoke 1 test VM                        #
###############################################################################

module "vm-spoke-1" {
  source = "../../modules/compute-vm"

  project_id = var.spoke_1_project_id
  region     = module.vpc-spoke-1.subnet_regions[keys(var.spoke_1_subnets).0]
  zone       = "${module.vpc-spoke-1.subnet_regions[keys(var.spoke_1_subnets).0]}-b"
  name       = "spoke-1-test-vm"
  network_interfaces = [{
    network    = module.vpc-spoke-1.self_link
    subnetwork = module.vpc-spoke-1.subnet_self_links[keys(var.spoke_1_subnets).0],
    nat        = false,
    addresses  = null
  }]
  instance_count = 1
}

###############################################################################
#                              TESTING: Spoke 2 test VM                       #
###############################################################################

module "vm-spoke-2" {
  source = "../../modules/compute-vm"

  project_id = var.spoke_2_project_id
  region     = module.vpc-spoke-2.subnet_regions[keys(var.spoke_2_subnets).0]
  zone       = "${module.vpc-spoke-2.subnet_regions[keys(var.spoke_2_subnets).0]}-b"
  name       = "spoke-2-test-vm"
  network_interfaces = [{
    network    = module.vpc-spoke-2.self_link
    subnetwork = module.vpc-spoke-2.subnet_self_links[keys(var.spoke_2_subnets).0],
    nat        = false,
    addresses  = null
  }]
  instance_count = 1
}

###############################################################################
#                      TESTING: On-Prem-In-a-Box resources                    #
###############################################################################

module "hub-to-onprem-cloud-vpn" {
  source = "../../modules/net-vpn-dynamic/"

  project_id = var.hub_project_id
  region     = module.vpc-hub.subnet_regions[keys(var.hub_subnets).0]
  network    = module.vpc-hub.self_link
  name       = "hub-net-to-on-prem"
  router_asn = 65001
  tunnels = {
    remote-1 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = 65002
      }
      bgp_session_range = "169.254.0.1/30"
      ike_version       = 2
      peer_ip           = module.on-prem-in-a-box.external_address
      shared_secret     = null
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = local.custom_routes_to_spokes
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
    }
  }
}

module "vpc-on-prem" {
  source = "../../modules/net-vpc"

  project_id = var.hub_project_id
  name       = "network-for-on-prem"
  subnets = {
    on-prem = {
      ip_cidr_range      = "172.16.1.0/28"
      region             = "europe-west1"
      secondary_ip_range = {}
    }
  }
}

module "on-prem-in-a-box" {
  source = "../../modules/on-prem-in-a-box/"

  project_id              = var.hub_project_id
  zone                    = "europe-west1-b"
  network                 = module.vpc-on-prem.name
  subnet_self_link        = module.vpc-on-prem.subnet_self_links["on-prem"]
  vpn_gateway_type        = "dynamic"
  peer_ip                 = module.hub-to-onprem-cloud-vpn.address
  local_ip_cidr_range     = var.on_prem_cidr_range
  shared_secret           = module.hub-to-onprem-cloud-vpn.random_secret
  peer_bgp_session_range  = "169.254.0.1/30"
  local_bgp_session_range = "169.254.0.2/30"
  peer_bgp_asn            = 65001
  local_bgp_asn           = 65002
  on_prem_dns_zone        = var.forwarding_dns_zone_domain
  cloud_dns_zone          = var.private_dns_zone_domain
  cloud_dns_forwarder_ip  = cidrhost(module.vpc-hub.subnet_ips[keys(var.hub_subnets).0], 2)
}

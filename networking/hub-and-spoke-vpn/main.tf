# Copyright 2021 Google LLC
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
  vm-instances = concat(
    module.vm-spoke-1.instances,
    module.vm-spoke-2.instances
  )
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y dnsutils"
  ])
}

################################################################################
#                                Hub networking                                #
################################################################################

module "vpc-hub" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "hub"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.hub-a
      name               = "hub-a"
      region             = var.regions.a
      secondary_ip_range = {}
    },
    {
      ip_cidr_range      = var.ip_ranges.hub-b
      name               = "hub-b"
      region             = var.regions.b
      secondary_ip_range = {}
    }
  ]
}

module "vpc-hub-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc-hub.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
}

module "vpn-hub-a" {
  source     = "../../modules/net-vpn-dynamic"
  project_id = var.project_id
  region     = var.regions.a
  network    = module.vpc-hub.name
  name       = "hub-a"
  router_asn = var.bgp_asn.hub
  tunnels = {
    spoke-1 = {
      bgp_peer = {
        address = cidrhost(var.bgp_interface_ranges.spoke-1, 2)
        asn     = var.bgp_asn.spoke-1
      }
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = {
          (var.bgp_custom_advertisements.hub-to-spoke-1) = "spoke-2"
        }
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
      bgp_session_range = "${cidrhost(var.bgp_interface_ranges.spoke-1, 1)}/30"
      ike_version       = 2
      peer_ip           = module.vpn-spoke-1.address
      router            = null
      shared_secret     = ""
    }
  }
}

module "vpn-hub-b" {
  source     = "../../modules/net-vpn-dynamic"
  project_id = var.project_id
  region     = var.regions.b
  network    = module.vpc-hub.name
  name       = "hub-b"
  router_asn = var.bgp_asn.hub
  tunnels = {
    spoke-2 = {
      bgp_peer = {
        address = cidrhost(var.bgp_interface_ranges.spoke-2, 2)
        asn     = var.bgp_asn.spoke-2
      }
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = {
          (var.bgp_custom_advertisements.hub-to-spoke-2) = "spoke-1"
        }
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
      bgp_session_range = "${cidrhost(var.bgp_interface_ranges.spoke-2, 1)}/30"
      ike_version       = 2
      peer_ip           = module.vpn-spoke-2.address
      router            = null
      shared_secret     = ""
    }
  }
}

################################################################################
#                              Spoke 1 networking                              #
################################################################################

module "vpc-spoke-1" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "spoke-1"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.spoke-1-a
      name               = "spoke-1-a"
      region             = var.regions.a
      secondary_ip_range = {}
    },
    {
      ip_cidr_range      = var.ip_ranges.spoke-1-b
      name               = "spoke-1-b"
      region             = var.regions.b
      secondary_ip_range = {}
    }
  ]
}

module "vpc-spoke-1-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc-spoke-1.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
}

module "vpn-spoke-1" {
  source     = "../../modules/net-vpn-dynamic"
  project_id = var.project_id
  region     = var.regions.a
  network    = module.vpc-spoke-1.name
  name       = "spoke-1"
  router_asn = var.bgp_asn.spoke-1
  tunnels = {
    hub = {
      bgp_peer = {
        address = cidrhost(var.bgp_interface_ranges.spoke-1, 1)
        asn     = var.bgp_asn.hub
      }
      bgp_peer_options  = null
      bgp_session_range = "${cidrhost(var.bgp_interface_ranges.spoke-1, 2)}/30"
      ike_version       = 2
      peer_ip           = module.vpn-hub-a.address
      router            = null
      shared_secret     = module.vpn-hub-a.random_secret
    }
  }
}

module "nat-spoke-1" {
  source        = "../../modules/net-cloudnat"
  project_id    = var.project_id
  region        = var.regions.a
  name          = "spoke-1"
  router_create = false
  router_name   = module.vpn-spoke-1.router_name
}

################################################################################
#                              Spoke 2 networking                              #
################################################################################

module "vpc-spoke-2" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "spoke-2"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.spoke-2-a
      name               = "spoke-2-a"
      region             = var.regions.a
      secondary_ip_range = {}
    },
    {
      ip_cidr_range      = var.ip_ranges.spoke-2-b
      name               = "spoke-2-b"
      region             = var.regions.b
      secondary_ip_range = {}
    }
  ]
}

module "vpc-spoke-2-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc-spoke-2.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
}

module "vpn-spoke-2" {
  source     = "../../modules/net-vpn-dynamic"
  project_id = var.project_id
  region     = var.regions.a
  network    = module.vpc-spoke-2.name
  name       = "spoke-2"
  router_asn = var.bgp_asn.spoke-2
  tunnels = {
    hub = {
      bgp_peer = {
        address = cidrhost(var.bgp_interface_ranges.spoke-2, 1)
        asn     = var.bgp_asn.hub
      }
      bgp_peer_options  = null
      bgp_session_range = "${cidrhost(var.bgp_interface_ranges.spoke-2, 2)}/30"
      ike_version       = 2
      peer_ip           = module.vpn-hub-b.address
      router            = null
      shared_secret     = module.vpn-hub-b.random_secret
    }
  }
}

module "nat-spoke-2" {
  source        = "../../modules/net-cloudnat"
  project_id    = var.project_id
  region        = var.regions.a
  name          = "spoke-2"
  router_create = false
  router_name   = module.vpn-spoke-2.router_name
}

################################################################################
#                                   Test VMs                                   #
################################################################################

module "vm-spoke-1" {
  source     = "../../modules/compute-vm"
  project_id = var.project_id
  region     = var.regions.b
  name       = "spoke-1-test"
  network_interfaces = [{
    network    = module.vpc-spoke-1.self_link
    subnetwork = module.vpc-spoke-1.subnet_self_links["${var.regions.b}/spoke-1-b"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  tags     = ["ssh"]
  metadata = { startup-script = local.vm-startup-script }
}

module "vm-spoke-2" {
  source     = "../../modules/compute-vm"
  project_id = var.project_id
  region     = var.regions.b
  name       = "spoke-2-test"
  network_interfaces = [{
    network    = module.vpc-spoke-2.self_link
    subnetwork = module.vpc-spoke-2.subnet_self_links["${var.regions.b}/spoke-2-b"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  tags     = ["ssh"]
  metadata = { startup-script = local.vm-startup-script }
}

################################################################################
#                                  DNS zones                                   #
################################################################################

module "dns-host" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "private"
  name            = "example"
  domain          = "example.com."
  client_networks = [module.vpc-hub.self_link]
  recordsets = [
    for instance in local.vm-instances : {
      name    = instance.name, type = "A", ttl = 300,
      records = [instance.network_interface.0.network_ip]
    }
  ]
}

module "dns-spoke-1" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "peering"
  name            = "spoke-1"
  domain          = "example.com."
  client_networks = [module.vpc-spoke-1.self_link]
  peer_network    = module.vpc-hub.self_link
}

module "dns-spoke-2" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "peering"
  name            = "spoke-2"
  domain          = "example.com."
  client_networks = [module.vpc-spoke-2.self_link]
  peer_network    = module.vpc-hub.self_link
}

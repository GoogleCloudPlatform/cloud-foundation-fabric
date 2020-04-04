/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  bgp_interface_gcp    = "${cidrhost(var.bgp_interface_ranges.gcp, 1)}"
  bgp_interface_onprem = "${cidrhost(var.bgp_interface_ranges.gcp, 2)}"
  netblocks = {
    dns        = data.google_netblock_ip_ranges.dns-forwarders.cidr_blocks_ipv4.0
    private    = data.google_netblock_ip_ranges.private-googleapis.cidr_blocks_ipv4.0
    restricted = data.google_netblock_ip_ranges.restricted-googleapis.cidr_blocks_ipv4.0
  }
  vips = {
    private    = [for i in range(4) : cidrhost(local.netblocks.private, i)]
    restricted = [for i in range(4) : cidrhost(local.netblocks.restricted, i)]
  }
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion dnsutils kubectl"
  ])
}

data "google_netblock_ip_ranges" "dns-forwarders" {
  range_type = "dns-forwarders"
}

data "google_netblock_ip_ranges" "private-googleapis" {
  range_type = "private-googleapis"
}

data "google_netblock_ip_ranges" "restricted-googleapis" {
  range_type = "restricted-googleapis"
}

################################################################################
#                                  Networking                                  #
################################################################################

module "vpc" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "to-onprem"
  subnets = {
    default = {
      ip_cidr_range      = var.ip_ranges.gcp
      region             = var.region
      secondary_ip_range = {}
    }
  }
}

module "vpc-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc.name
  admin_ranges_enabled = true
  admin_ranges         = values(var.ip_ranges)
  ssh_source_ranges    = var.ssh_source_ranges
}

module "vpn" {
  source     = "../../modules/net-vpn-dynamic"
  project_id = var.project_id
  region     = module.vpc.subnet_regions["default"]
  network    = module.vpc.name
  name       = "to-onprem"
  router_asn = var.bgp_asn.gcp
  tunnels = {
    onprem = {
      bgp_peer = {
        address = local.bgp_interface_onprem
        asn     = var.bgp_asn.onprem
      }
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = {
          (local.netblocks.dns)        = "IAP forwarders"
          (local.netblocks.private)    = "private.gooogleapis.com"
          (local.netblocks.restricted) = "restricted.gooogleapis.com"
        }
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
      bgp_session_range = "${local.bgp_interface_gcp}/30"
      ike_version       = 2
      peer_ip           = module.vm-onprem.external_ips.0
      shared_secret     = ""
    }
  }
}

module "nat" {
  source        = "../../modules/net-cloudnat"
  project_id    = var.project_id
  region        = module.vpc.subnet_regions.default
  name          = "default"
  router_create = false
  router_name   = module.vpn.router_name
}

################################################################################
#                                     DNS                                      #
################################################################################

module "dns-gcp" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "private"
  name            = "gcp-example"
  domain          = "gcp.example.org."
  client_networks = [module.vpc.self_link]
  recordsets = concat(
    [{ name = "localhost", type = "A", ttl = 300, records = ["127.0.0.1"] }],
    [
      for name, ip in zipmap(module.vm-test.names, module.vm-test.internal_ips) :
      { name = name, type = "A", ttl = 300, records = [ip] }
    ]
  )
}

module "dns-api" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "private"
  name            = "googleapis"
  domain          = "googleapis.com."
  client_networks = [module.vpc.self_link]
  recordsets = [
    { name = "*", type = "CNAME", ttl = 300, records = ["private.googleapis.com."] },
    { name = "private", type = "A", ttl = 300, records = local.vips.private },
    { name = "restricted", type = "A", ttl = 300, records = local.vips.restricted },
  ]
}

module "dns-onprem" {
  source          = "../../modules/dns"
  project_id      = var.project_id
  type            = "forwarding"
  name            = "onprem-example"
  domain          = "onprem.example.org."
  client_networks = [module.vpc.self_link]
  forwarders      = [cidrhost(var.ip_ranges.onprem, 3)]
}

resource "google_dns_policy" "inbound" {
  provider                  = google-beta
  project                   = var.project_id
  name                      = "gcp-inbound"
  enable_inbound_forwarding = true
  networks {
    network_url = module.vpc.self_link
  }
}

################################################################################
#                                Test instance                                 #
################################################################################

module "service-account-gce" {
  source     = "../../modules/iam-service-accounts"
  project_id = var.project_id
  names      = ["gce-test"]
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "vm-test" {
  source     = "../../modules/compute-vm"
  project_id = var.project_id
  region     = module.vpc.subnet_regions.default
  zone       = "${module.vpc.subnet_regions.default}-b"
  name       = "test"
  network_interfaces = [{
    network    = module.vpc.self_link,
    subnetwork = module.vpc.subnet_self_links.default,
    nat        = false,
    addresses  = null
  }]
  metadata               = { startup-script = local.vm-startup-script }
  service_account        = module.service-account-gce.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

################################################################################
#                                   On prem                                    #
################################################################################

module "config-onprem" {
  source              = "../../modules/cos-container/onprem"
  config_variables    = { dns_forwarder_address = var.dns_forwarder_address }
  coredns_config      = "assets/Corefile"
  local_ip_cidr_range = var.ip_ranges.onprem
  vpn_config = {
    peer_ip       = module.vpn.address
    shared_secret = module.vpn.random_secret
    type          = "dynamic"
  }
  vpn_dynamic_config = {
    local_bgp_asn     = var.bgp_asn.onprem
    local_bgp_address = local.bgp_interface_onprem
    peer_bgp_asn      = var.bgp_asn.gcp
    peer_bgp_address  = local.bgp_interface_gcp
  }
}

module "service-account-onprem" {
  source     = "../../modules/iam-service-accounts"
  project_id = var.project_id
  names      = ["gce-onprem"]
  iam_project_roles = {
    (var.project_id) = [
      "roles/compute.viewer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "vm-onprem" {
  source        = "../../modules/compute-vm"
  project_id    = var.project_id
  region        = var.region
  zone          = "${var.region}-b"
  instance_type = "f1-micro"
  name          = "onprem"
  boot_disk = {
    image = "ubuntu-os-cloud/ubuntu-1804-lts"
    type  = "pd-ssd"
    size  = 10
  }
  metadata = {
    user-data = module.config-onprem.cloud_config
  }
  network_interfaces = [{
    network    = module.vpc.name
    subnetwork = module.vpc.subnet_self_links.default
    nat        = true,
    addresses  = null
  }]
  service_account        = module.service-account-onprem.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

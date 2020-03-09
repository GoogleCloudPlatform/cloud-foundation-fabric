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
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion dnsutils kubectl"
  ])
}

data "google_netblock_ip_ranges" "private-googleapis" {
  range_type = "private-googleapis"
}

data "google_netblock_ip_ranges" "dns-forwarders" {
  range_type = "dns-forwarders"
}

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
          (data.google_netblock_ip_ranges.private-googleapis.cidr_blocks_ipv4.0) = "private-googleapis"
          (data.google_netblock_ip_ranges.dns-forwarders.cidr_blocks_ipv4.0)     = "dns-forwarders"
        }
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
      bgp_session_range = "${local.bgp_interface_gcp}/30"
      ike_version       = 2
      peer_ip           = module.on-prem.external_address
      shared_secret     = ""
    }
  }
}

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

# TODO: add service account, scopes and network tags support to onprem module

module "on-prem" {
  source                  = "../../modules/on-prem-in-a-box/"
  project_id              = var.project_id
  zone                    = "${var.region}-b"
  network                 = module.vpc.name
  subnet_self_link        = module.vpc.subnet_self_links.default
  vpn_gateway_type        = "dynamic"
  peer_ip                 = module.vpn.address
  local_ip_cidr_range     = var.ip_ranges.onprem
  shared_secret           = module.vpn.random_secret
  peer_bgp_session_range  = "${local.bgp_interface_gcp}/30"
  local_bgp_session_range = "${local.bgp_interface_gcp}/30"
  peer_bgp_asn            = var.bgp_asn.gcp
  local_bgp_asn           = var.bgp_asn.onprem
  cloud_dns_zone          = var.dns_domains.gcp
  on_prem_dns_zone        = var.dns_domains.onprem
  cloud_dns_forwarder_ip  = cidrhost(module.vpc.subnet_ips.default, 2)
}

# Copyright 2022 Google LLC
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

# tfdoc:file:description Creates the VPC and manages the firewall rules and ILB.

locals {
  listeners = { for aog in var.always_on_groups : format("%slb-%s", local.prefix, aog) => {
    region     = var.region
    subnetwork = local.subnetwork
    }
  }
  node_ips = { for node_name in local.node_netbios_names : node_name => {
    region     = var.region
    subnetwork = local.subnetwork
    }
  }
  internal_addresses = merge({
    format("%scluster", local.prefix) = {
      region     = var.region
      subnetwork = local.subnetwork
    }
    (local.witness_netbios_name) = {
      region     = var.region
      subnetwork = local.subnetwork
    }
  }, local.listeners, local.node_ips)
}

data "google_compute_zones" "zones" {
  count   = var.project_create == null ? 1 : 0
  project = local.vpc_project
  region  = var.region
}

data "google_compute_subnetwork" "subnetwork" {
  count   = var.project_create == null ? 1 : 0
  project = local.vpc_project
  name    = var.subnetwork
  region  = var.region
}

# Create VPC if required
module "vpc" {
  source = "../../../modules/net-vpc"

  project_id = local.vpc_project
  name       = var.network
  subnets = var.project_create != null ? [
    {
      ip_cidr_range = var.vpc_ip_cidr_range
      name          = var.subnetwork
      region        = var.region
    }
  ] : []
  vpc_create = var.project_create != null ? true : false
}

# Firewall rules required for WSFC nodes
module "firewall" {
  source              = "../../../modules/net-vpc-firewall"
  project_id          = local.vpc_project
  network             = local.network
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  custom_rules = {
    format("%sallow-all-between-wsfc-nodes", local.prefix) = {
      description          = "Allow all between WSFC nodes"
      direction            = "INGRESS"
      action               = "allow"
      sources              = [module.compute-service-account.email]
      targets              = [module.compute-service-account.email]
      ranges               = []
      use_service_accounts = true
      rules = [
        { protocol = "tcp", ports = [] },
        { protocol = "udp", ports = [] },
        { protocol = "icmp", ports = [] }
      ]
      extra_attributes = {}
    }
    format("%sallow-all-between-wsfc-witness", local.prefix) = {
      description          = "Allow all between WSFC witness nodes"
      direction            = "INGRESS"
      action               = "allow"
      sources              = [module.compute-service-account.email]
      targets              = [module.witness-service-account.email]
      ranges               = []
      use_service_accounts = true
      rules = [
        { protocol = "tcp", ports = [] },
        { protocol = "udp", ports = [] },
        { protocol = "icmp", ports = [] }
      ]
      extra_attributes = {}
    }
    format("%sallow-sql-to-wsfc-nodes", local.prefix) = {
      description          = "Allow SQL connections to WSFC nodes"
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      targets              = [module.compute-service-account.email]
      ranges               = var.sql_client_cidrs
      use_service_accounts = true
      rules = [
        { protocol = "tcp", ports = [1433] },
      ]
      extra_attributes = {}
    }
    format("%sallow-health-check-to-wsfc-nodes", local.prefix) = {
      description          = "Allow health checks to WSFC nodes"
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      targets              = [module.compute-service-account.email]
      ranges               = var.health_check_ranges
      use_service_accounts = true
      rules = [
        { protocol = "tcp", ports = [] },
      ]
      extra_attributes = {}
    }
  }
}

# IP Address reservation for cluster and listener
module "ip-addresses" {
  source     = "../../../modules/net-address"
  project_id = local.vpc_project

  internal_addresses = local.internal_addresses
}

# L4 Internal Load Balancer for SQL Listener
module "listener-ilb" {
  source   = "../../../modules/net-ilb"
  for_each = toset(var.always_on_groups)

  project_id = var.project_id
  region     = var.region

  name          = format("%s-%s-ilb", var.prefix, each.value)
  service_label = format("%s-%s-ilb", var.prefix, each.value)

  address    = module.ip-addresses.internal_addresses[format("%slb-%s", local.prefix, each.value)].address
  network    = local.network
  subnetwork = local.subnetwork

  backends = [for k, node in module.nodes : {
    failover       = false
    group          = node.group.self_link
    balancing_mode = "CONNECTION"
  }]

  health_check_config = {
    type    = "tcp",
    check   = { port = var.health_check_port },
    config  = var.health_check_config,
    logging = true
  }
}

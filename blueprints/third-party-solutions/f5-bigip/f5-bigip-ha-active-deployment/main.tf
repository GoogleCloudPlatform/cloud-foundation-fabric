/**
 * Copyright 2023 Google LLC
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
  project_id = (
    var.project_create
    ? module.project.project_id
    : var.project_id
  )
}

module "project" {
  source        = "../../../../modules/project"
  name          = var.project_id
  project_reuse = var.project_create ? null : {}
  services = [
    "compute.googleapis.com"
  ]
}

module "vpc-dataplane" {
  source     = "../../../../modules/net-vpc"
  project_id = local.project_id
  name       = "${var.prefix}-vpc-dataplane"
  ipv6_config = {
    enable_ula_internal = true
  }
  routes = {
    next-hop = {
      description   = "Route to virtual backend servers subnet."
      dest_range    = var.vpc_config.backend_vms_cidr
      next_hop_type = "ilb"
      next_hop      = var.forwarding_rules_config["ipv4"]["address"]
    }
  }
  subnets = [
    {
      ip_cidr_range = var.vpc_config.dataplane.subnets.clients.cidr
      ipv6          = {}
      name          = "${var.prefix}-clients"
      region        = var.region
    },
    {
      ip_cidr_range = var.vpc_config.dataplane.subnets.dataplane.cidr
      ipv6          = {}
      name          = "${var.prefix}-dataplane"
      region        = var.region
      secondary_ip_ranges = (
        var.vpc_config.dataplane.subnets.dataplane.secondary_ip_ranges
      )
    }
  ]
}

module "firewall-rules-dataplane" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = local.project_id
  network    = module.vpc-dataplane.name
  ingress_rules = {
    allow-clients-to-f5 = {
      priority             = 1001
      source_ranges        = [var.vpc_config.dataplane.subnets.clients.cidr]
      targets              = [module.f5-sa.email]
      use_service_accounts = true
    }
    allow-f5-to-backends = {
      priority             = 1002
      sources              = [module.f5-sa.email]
      targets              = [module.backends-sa.email]
      use_service_accounts = true
    }
  }
}

module "nat-dataplane" {
  source         = "../../../../modules/net-cloudnat"
  name           = "${var.prefix}-nat-dataplane"
  project_id     = local.project_id
  region         = var.region
  router_network = module.vpc-dataplane.self_link
}

# Management

module "vpc-management" {
  source     = "../../../../modules/net-vpc"
  project_id = local.project_id
  name       = "${var.prefix}-vpc-management"
  ipv6_config = {
    enable_ula_internal = true
  }
  subnets = [
    {
      ip_cidr_range = var.vpc_config.management.subnets.management.cidr
      ipv6          = {}
      name          = "${var.prefix}-management"
      region        = var.region
    }
  ]
}

# It installs the default firewall admin rules
module "firewall-rules-management" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = local.project_id
  network    = module.vpc-management.name
}

module "nat-management" {
  source         = "../../../../modules/net-cloudnat"
  name           = "${var.prefix}-nat-management"
  project_id     = local.project_id
  region         = var.region
  router_network = module.vpc-management.self_link
}

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

# tfdoc:file:description Landing VPC and related resources.

locals {
  landing_subnets = {
    for k, v in var.regions : k => {
      untrusted = {
        name          = "landing-untrusted-default-${local.region_shortnames[v]}"
        region        = v
        ip_cidr_range = var.landing_subnets_ip_cidrs[k].untrusted
        description   = "Default ${v} subnet for landing untrusted"
      }
      trusted = {
        name          = "landing-trusted-default-${local.region_shortnames[v]}"
        region        = v
        ip_cidr_range = var.landing_subnets_ip_cidrs[k].trusted
        description   = "Default ${v} subnet for landing trusted"
      }
    }
  }
  landing_subnet_ids = {
    for k, v in local.landing_subnets : k => {
      untrusted = "${v.untrusted.region}/${v.untrusted.name}"
      trusted   = "${v.trusted.region}/${v.trusted.name}"
    }
  }
}

module "landing-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-landing-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networkmanagement.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled = true
  }
  iam = {
    "roles/dns.admin" = compact([
      try(local.service_accounts.project-factory-prod, null)
    ])
    (local.custom_roles.service_project_network_admin) = compact([
      try(local.service_accounts.project-factory-prod, null)
    ])
  }
}

# Untrusted VPC

module "landing-untrusted-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.landing-project.project_id
  name       = "prod-untrusted-landing-0"
  mtu        = 1500
  dns_policy = {
    inbound = false
    logging = false
  }
  create_googleapis_routes = {
    private    = false
    restricted = false
  }
  subnets = [
    for k in local.landing_subnets : k.untrusted
  ]
  data_folder = "${var.factories_config.data_dir}/subnets/landing-untrusted"
}

module "landing-untrusted-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.landing-untrusted-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/landing-untrusted"
  }
}

# NAT

moved {
  from = module.landing-nat-ew1
  to   = module.landing-nat-primary
}

module "landing-nat-primary" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.landing-project.project_id
  region         = var.regions.primary
  name           = local.region_shortnames[var.regions.primary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.primary]}"
  router_network = module.landing-untrusted-vpc.name
  router_asn     = 4200001024
}

moved {
  from = module.landing-nat-ew4
  to   = module.landing-nat-secondary
}

module "landing-nat-secondary" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.landing-project.project_id
  region         = var.regions.secondary
  name           = local.region_shortnames[var.regions.secondary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.secondary]}"
  router_network = module.landing-untrusted-vpc.name
  router_asn     = 4200001024
}

# Trusted VPC

module "landing-trusted-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-trusted-landing-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  data_folder                     = "${var.factories_config.data_dir}/subnets/landing-trusted"
  dns_policy = {
    inbound = true
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  subnets = [
    for k in local.landing_subnets : k.trusted
  ]
}

module "landing-trusted-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.landing-trusted-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/landing-trusted"
  }
}

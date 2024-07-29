/**
 * Copyright 2024 Google LLC
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

module "landing-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-landing-0"
  parent          = var.folder_ids.networking-prod
  prefix          = var.prefix
  services = concat([
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "stackdriver.googleapis.com",
    ],
    (
      var.enable_ncc_ra
      ? ["networkconnectivity.googleapis.com"]
      : []
    )
  )
  shared_vpc_host_config = {
    enabled = true
  }
}

# DMZ (untrusted) VPC

module "dmz-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.landing-project.project_id
  name       = "prod-dmz-0"
  mtu        = 1500
  dns_policy = {
    inbound = true
    logging = var.dns.enable_logging
  }
  create_googleapis_routes = null
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/dmz"
  }
  delete_default_routes_on_create = true
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      next_hop      = "default-internet-gateway"
      next_hop_type = "gateway"
      priority      = 1000
    }
  }
}

module "dmz-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.dmz-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/dmz"
  }
}

# NAT

module "dmz-nat-primary" {
  source         = "../../../modules/net-cloudnat"
  count          = var.enable_cloud_nat ? 1 : 0
  project_id     = module.landing-project.project_id
  region         = var.regions.primary
  name           = local.region_shortnames[var.regions.primary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.primary]}"
  router_network = module.dmz-vpc.name
}

module "dmz-nat-secondary" {
  source         = "../../../modules/net-cloudnat"
  count          = var.enable_cloud_nat ? 1 : 0
  project_id     = module.landing-project.project_id
  region         = var.regions.secondary
  name           = local.region_shortnames[var.regions.secondary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.secondary]}"
  router_network = module.dmz-vpc.name
}

# Landing (trusted) VPC

module "landing-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-landing-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/landing"
  }
  dns_policy = {
    inbound = true
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "landing-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/landing"
  }
}

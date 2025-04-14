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

locals {
  # streamline VPC configuration conditionals for modules by moving them here
  landing_cfg = {
    cloudnat = (
      local.spoke_connection != "ncc" &&
      var.vpc_configs.landing.cloudnat.enable == true
    )
    dns_logging = var.vpc_configs.landing.dns.enable_logging == true
    dns_policy  = var.vpc_configs.landing.dns.create_inbound_policy == true
    fw_classic = (
      local.spoke_connection != "ncc" &&
      var.vpc_configs.landing.firewall.use_classic == true
    )
    fw_order = (
      var.vpc_configs.landing.firewall.policy_has_priority == true
      ? "BEFORE_CLASSIC_FIREWALL"
      : "AFTER_CLASSIC_FIREWALL"
    )
    fw_policy = (
      local.spoke_connection != "ncc" &&
      var.vpc_configs.landing.firewall.create_policy == true
    )
  }
}

module "landing-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-landing-0"
  parent = coalesce(
    var.folder_ids.networking-prod,
    var.folder_ids.networking
  )
  prefix = var.prefix
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
  tag_bindings = local.has_env_folders ? {} : {
    environment = local.env_tag_values["prod"]
  }
}

module "landing-vpc" {
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-landing-0"
  mtu                             = var.vpc_configs.landing.mtu
  delete_default_routes_on_create = true
  dns_policy = !local.landing_cfg.dns_policy ? {} : {
    inbound = true
    logging = local.landing_cfg.dns_logging
  }
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.subnets}/landing"
  }
  firewall_policy_enforcement_order = local.landing_cfg.fw_order
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      next_hop      = "default-internet-gateway"
      next_hop_type = "gateway"
      priority      = 1000
    }
  }
}

module "landing-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.landing_cfg.fw_classic ? 1 : 0
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = var.factories_config.firewall.cidr_file
    rules_folder  = "${var.factories_config.firewall.classic_rules}/landing"
  }
}

module "landing-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  count     = local.landing_cfg.fw_policy ? 1 : 0
  name      = "prod-landing-0"
  parent_id = module.landing-project.project_id
  region    = "global"
  attachments = {
    landing-0 = module.landing-vpc.id
  }
  factories_config = {
    cidr_file_path          = var.factories_config.firewall.cidr_file
    egress_rules_file_path  = "${var.factories_config.firewall.policy_rules}/landing/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.firewall.policy_rules}/landing/ingress.yaml"
  }
  security_profile_group_ids = var.security_profile_groups
}

module "landing-nat-primary" {
  source         = "../../../modules/net-cloudnat"
  count          = local.landing_cfg.cloudnat ? 1 : 0
  project_id     = module.landing-project.project_id
  region         = var.regions.primary
  name           = local.region_shortnames[var.regions.primary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.primary]}"
  router_network = module.landing-vpc.name
}

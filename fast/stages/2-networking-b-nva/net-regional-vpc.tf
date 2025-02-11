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

# tfdoc:file:description Regional VPCs and related resources.

locals {
  # streamline VPC configuration conditionals for modules by moving them here
  regpri_cfg = {
    dns_logging = var.vpc_configs.regional_primary.dns.enable_logging == true
    dns_policy  = var.vpc_configs.regional_primary.dns.create_inbound_policy == true
    fw_classic = (
      var.network_mode == "regional_vpc" &&
      var.vpc_configs.regional_primary.firewall.use_classic == true
    )
    fw_order = (
      var.vpc_configs.regional_primary.firewall.policy_has_priority == true
      ? "BEFORE_CLASSIC_FIREWALL"
      : "AFTER_CLASSIC_FIREWALL"
    )
    fw_policy = (
      var.network_mode == "regional_vpc" &&
      var.vpc_configs.regional_primary.firewall.create_policy == true
    )
  }
  regsec_cfg = {
    dns_logging = var.vpc_configs.regional_secondary.dns.enable_logging == true
    dns_policy  = var.vpc_configs.regional_secondary.dns.create_inbound_policy == true
    fw_classic = (
      var.network_mode == "regional_vpc" &&
      var.vpc_configs.regional_secondary.firewall.use_classic == true
    )
    fw_order = (
      var.vpc_configs.regional_secondary.firewall.policy_has_priority == true
      ? "BEFORE_CLASSIC_FIREWALL"
      : "AFTER_CLASSIC_FIREWALL"
    )
    fw_policy = (
      var.network_mode == "regional_vpc" &&
      var.vpc_configs.regional_secondary.firewall.create_policy == true
    )
  }
}

module "regional-primary-vpc" {
  count                             = (var.network_mode == "regional_vpc") ? 1 : 0
  source                            = "../../../modules/net-vpc"
  project_id                        = module.landing-project.project_id
  name                              = "prod-regional-primary-0"
  delete_default_routes_on_create   = true
  firewall_policy_enforcement_order = local.regpri_cfg.fw_order
  mtu                               = var.vpc_configs.regional_primary.mtu
  dns_policy = !local.regpri_cfg.dns_policy ? {} : {
    inbound = true
    logging = local.regpri_cfg.dns_logging
  }
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.subnets}/regional-pri"
  }
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      next_hop_type = "ilb"
      next_hop      = module.ilb-regional-nva-regional-vpc["primary"].forwarding_rule_addresses[""]
    }
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "regional-primary-firewall" {
  count      = local.regpri_cfg.fw_classic ? 1 : 0
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.regional-primary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = var.factories_config.firewall.cidr_file
    rules_folder  = "${var.factories_config.firewall.classic_rules}/regional-pri"
  }
}

module "regional-primary-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  count     = local.regpri_cfg.fw_policy ? 1 : 0
  name      = "prod-regional-primary-0"
  parent_id = module.landing-project.project_id
  region    = "global"
  attachments = {
    regional-primary-0 = module.regional-primary-vpc[0].id
  }
  factories_config = {
    cidr_file_path          = var.factories_config.firewall.cidr_file
    egress_rules_file_path  = "${var.factories_config.firewall.policy_rules}/regional-primary/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.firewall.policy_rules}/regional-primary/ingress.yaml"
  }
  security_profile_group_ids = var.security_profile_groups
}

# Regional Secondary VPC

module "regional-secondary-vpc" {
  count                             = (var.network_mode == "regional_vpc") ? 1 : 0
  source                            = "../../../modules/net-vpc"
  project_id                        = module.landing-project.project_id
  name                              = "prod-regional-secondary-0"
  delete_default_routes_on_create   = true
  firewall_policy_enforcement_order = local.regsec_cfg.fw_order
  mtu                               = var.vpc_configs.regional_secondary.mtu
  dns_policy = !local.regsec_cfg.dns_policy ? {} : {
    inbound = true
    logging = local.regsec_cfg.dns_logging
  }
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.subnets}/regional-sec"
  }
  routes = {
    default = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      next_hop_type = "ilb"
      next_hop      = module.ilb-regional-nva-regional-vpc["secondary"].forwarding_rule_addresses[""]
    }
  }
  # Set explicit routes for googleapis in case the default route is deleted
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "regional-secondary-firewall" {
  count      = local.regsec_cfg.fw_classic ? 1 : 0
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.regional-secondary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = var.factories_config.firewall.cidr_file
    rules_folder  = "${var.factories_config.firewall.classic_rules}/regional-sec"
  }
}

module "regional-secondary-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  count     = local.regsec_cfg.fw_policy ? 1 : 0
  name      = "prod-regional-secondary-0"
  parent_id = module.landing-project.project_id
  region    = "global"
  attachments = {
    regional-secondary-0 = module.regional-secondary-vpc[0].id
  }
  factories_config = {
    cidr_file_path          = var.factories_config.firewall.cidr_file
    egress_rules_file_path  = "${var.factories_config.firewall.policy_rules}/regional-secondary/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.firewall.policy_rules}/regional-secondary/ingress.yaml"
  }
  security_profile_group_ids = var.security_profile_groups
}

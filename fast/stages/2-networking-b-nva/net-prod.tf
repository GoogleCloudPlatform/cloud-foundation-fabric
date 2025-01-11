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

# tfdoc:file:description Production spoke VPC and related resources.

locals {
  # streamline VPC configuration conditionals for modules by moving them here
  prod_cfg = {
    dns_logging = var.vpc_configs.prod.dns.enable_logging == true
    dns_policy  = var.vpc_configs.prod.dns.create_inbound_policy == true
    fw_classic  = var.vpc_configs.prod.firewall.use_classic == true
    fw_order = (
      var.vpc_configs.prod.firewall.policy_has_priority == true
      ? "BEFORE_CLASSIC_FIREWALL"
      : "AFTER_CLASSIC_FIREWALL"
    )
    fw_policy = var.vpc_configs.prod.firewall.create_policy == true
  }
}

module "prod-spoke-project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-net-spoke-0"
  parent = coalesce(
    var.folder_ids.networking-prod,
    var.folder_ids.networking
  )
  prefix = var.prefix
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
  shared_vpc_host_config = {
    enabled = true
  }
  metric_scopes = [module.landing-project.project_id]
  # optionally delegate a fixed set of IAM roles to selected principals
  iam = {
    (var.custom_roles.project_iam_viewer) = try(local.iam_viewer_principals["prod"], [])
  }
  iam_bindings = (
    lookup(local.iam_delegated_principals, "prod", null) == null ? {} : {
      sa_delegated_grants = {
        role    = "roles/resourcemanager.projectIamAdmin"
        members = try(local.iam_delegated_principals["prod"], [])
        condition = {
          title       = "prod_stage3_sa_delegated_grants"
          description = "${var.environments["prod"].name} host project delegated grants."
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            local.iam_delegated
          )
        }
      }
    }
  )
  tag_bindings = local.has_env_folders ? {} : {
    environment = local.env_tag_values["prod"]
  }
}

module "prod-spoke-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.prod-spoke-project.project_id
  name       = "prod-spoke-0"
  mtu        = var.vpc_configs.prod.mtu
  dns_policy = !local.prod_cfg.dns_policy ? {} : {
    inbound = true
    logging = local.prod_cfg.dns_logging
  }
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.subnets}/prod"
  }
  delete_default_routes_on_create   = true
  firewall_policy_enforcement_order = local.prod_cfg.fw_order
  psa_configs                       = var.psa_ranges.prod
  # Set explicit routes for googleapis; send everything else to NVAs
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
  routes = (var.network_mode == "ncc_ra") ? null : {
    nva-primary-to-primary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = [local.region_shortnames[var.regions.primary]]
      next_hop_type = "ilb"
      next_hop      = local.nva_load_balancers.primary
    }
    nva-secondary-to-secondary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1000
      tags          = [local.region_shortnames[var.regions.secondary]]
      next_hop_type = "ilb"
      next_hop      = local.nva_load_balancers.secondary
    }
    nva-primary-to-secondary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = [local.region_shortnames[var.regions.primary]]
      next_hop_type = "ilb"
      next_hop      = local.nva_load_balancers.secondary
    }
    nva-secondary-to-primary = {
      dest_range    = "0.0.0.0/0"
      priority      = 1001
      tags          = [local.region_shortnames[var.regions.secondary]]
      next_hop_type = "ilb"
      next_hop      = local.nva_load_balancers.primary
    }
  }
}

module "prod-spoke-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.prod_cfg.fw_classic ? 1 : 0
  project_id = module.prod-spoke-project.project_id
  network    = module.prod-spoke-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = var.factories_config.firewall.cidr_file
    rules_folder  = "${var.factories_config.firewall.classic_rules}/prod"
  }
}

module "prod-firewall-policy" {
  source    = "../../../modules/net-firewall-policy"
  count     = local.prod_cfg.fw_policy ? 1 : 0
  name      = "prod-spoke-0"
  parent_id = module.prod-spoke-project.project_id
  region    = "global"
  attachments = {
    prod-spoke-0 = module.prod-spoke-vpc.id
  }
  factories_config = {
    cidr_file_path          = var.factories_config.firewall.cidr_file
    egress_rules_file_path  = "${var.factories_config.firewall.policy_rules}/prod/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.firewall.policy_rules}/prod/ingress.yaml"
  }
  security_profile_group_ids = var.security_profile_groups
}

module "peering-prod" {
  source        = "../../../modules/net-vpc-peering"
  prefix        = "prod-peering-0"
  local_network = module.prod-spoke-vpc.self_link
  peer_network  = module.landing-vpc.self_link
}

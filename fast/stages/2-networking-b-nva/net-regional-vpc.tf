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

# Regional Primary VPC

module "regional-primary-vpc" {
  count                           = (var.network_mode == "regional_vpc") ? 1 : 0
  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-regional-primary-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/regional-pri"
  }
  dns_policy = {
    inbound = true
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
  count      = (var.network_mode == "regional_vpc") ? 1 : 0
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.regional-primary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/regional-pri"
  }
}

# Regional Secondary VPC

module "regional-secondary-vpc" {
  count = (var.network_mode == "regional_vpc") ? 1 : 0

  source                          = "../../../modules/net-vpc"
  project_id                      = module.landing-project.project_id
  name                            = "prod-regional-secondary-0"
  delete_default_routes_on_create = true
  mtu                             = 1500
  factories_config = {
    context        = { regions = var.regions }
    subnets_folder = "${var.factories_config.data_dir}/subnets/regional-sec"
  }
  dns_policy = {
    inbound = true
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
  count = (var.network_mode == "regional_vpc") ? 1 : 0

  source     = "../../../modules/net-vpc-firewall"
  project_id = module.landing-project.project_id
  network    = module.regional-secondary-vpc[0].name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/regional-sec"
  }
}

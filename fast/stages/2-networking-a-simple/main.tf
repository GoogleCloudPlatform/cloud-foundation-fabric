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

# tfdoc:file:description Networking folder and hierarchical policy.

locals {
  env_tag_values = {
    for k, v in var.environments :
    k => var.tag_values["environment/${v.tag_name}"]
  }
  has_env_folders = var.folder_ids.networking-dev != null
  iam_delegated = join(",", formatlist("'%s'", [
    "roles/composer.sharedVpcAgent",
    "roles/compute.networkUser",
    "roles/compute.networkViewer",
    "roles/container.hostServiceAgentUser",
    "roles/multiclusterservicediscovery.serviceAgent",
    "roles/vpcaccess.user",
  ]))
  iam_admin_delegated = try(
    var.stage_configs["networking"].iam_admin_delegated, {}
  )
  iam_viewer = try(
    var.stage_configs["networking"].iam_viewer, {}
  )
  # combine all regions from variables and subnets
  regions = distinct(concat(
    values(var.regions),
    values(module.dev-spoke-vpc.subnet_regions),
    values(module.landing-vpc.subnet_regions),
    values(module.prod-spoke-vpc.subnet_regions),
  ))
  spoke_connection = coalesce(
    var.spoke_configs.peering_configs != null ? "peering" : null,
    var.spoke_configs.vpn_configs != null ? "vpn" : null,
    var.spoke_configs.ncc_configs != null ? "ncc" : null,
  )
}

module "folder" {
  source        = "../../../modules/folder"
  folder_create = false
  id            = var.folder_ids.networking
  contacts = (
    var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
  firewall_policy = {
    name   = "default"
    policy = module.firewall-policy-default.id
  }
}

module "firewall-policy-default" {
  source    = "../../../modules/net-firewall-policy"
  name      = var.factories_config.firewall.hierarchical.policy_name
  parent_id = module.folder.id
  factories_config = {
    cidr_file_path          = var.factories_config.firewall.cidr_file
    ingress_rules_file_path = var.factories_config.firewall.hierarchical.ingress_rules
  }
}


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
  _network_factory_path = try(
    pathexpand(var.factories_config.vpcs), null
  )
  _network_factory_files = try(
    fileset(local._network_factory_path, "**/*.yaml"),
    []
  )

  iam_delegated = join(",", formatlist("'%s'", [
    "roles/composer.sharedVpcAgent",
    "roles/compute.networkUser",
    "roles/compute.networkViewer",
    "roles/container.hostServiceAgentUser",
    "roles/multiclusterservicediscovery.serviceAgent",
    "roles/vpcaccess.user",
  ]))
  iam_delegated_principals = var.iam_admin_delegated
  iam_viewer_principals    = var.iam_viewer
}

module "folder" {
  source        = "../folder"
  folder_create = false
  id            = var.parent_id
  contacts = (
    var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
  # firewall_policy = {
  #   name   = "default"
  #   policy = module.firewall-policy-default.id
  # }
}

# module "firewall-policy-default" {
#   source    = "../net-firewall-policy"
#   name      = var.factories_config.firewall_policy_name
#   parent_id = module.folder.id
#   factories_config = {
#     cidr_file_path          = "${var.factories_config.data_dir}/cidrs.yaml"
#     ingress_rules_file_path = "${var.factories_config.data_dir}/hierarchical-ingress-rules.yaml"
#   }
# }

/**
 * Copyright 2025 Google LLC
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
  #TODO(sruffilli): yaml file name should be == project name, unless overridden explicitly by a "name" attribute in project_config.
  _network_projects = {
    for f in local._network_factory_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._network_factory_path, "-")}/${f}"
    ))
  }

  env_tag_values = {
    for k, v in var.environments : k => var.tag_values["environment/${v.tag_name}"]
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
  iam_delegated_principals = try(
    var.stage_config["networking"].iam_delegated_principals, {}
  )
  iam_viewer_principals = try(
    var.stage_config["networking"].iam_viewer_principals, {}
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
  # firewall_policy = {
  #   name   = "default"
  #   policy = module.firewall-policy-default.id
  # }
}

# module "firewall-policy-default" {
#   source    = "../../../modules/net-firewall-policy"
#   name      = var.factories_config.firewall_policy_name
#   parent_id = module.folder.id
#   factories_config = {
#     cidr_file_path          = "${var.factories_config.data_dir}/cidrs.yaml"
#     ingress_rules_file_path = "${var.factories_config.data_dir}/hierarchical-ingress-rules.yaml"
#   }
# }

# module "network-projects" {
#   source          = "../../../modules/project"
#   billing_account = var.billing_account.id
#   name            = "net-project-0"
#   parent = coalesce(
#     var.folder_ids.networking-prod,
#     var.folder_ids.networking
#   )
#   prefix = var.prefix
#   services = [
#     "container.googleapis.com",
#     "compute.googleapis.com",
#     "dns.googleapis.com",
#     "iap.googleapis.com",
#     "networkmanagement.googleapis.com",
#     "networksecurity.googleapis.com",
#     "servicenetworking.googleapis.com",
#     "stackdriver.googleapis.com",
#     "vpcaccess.googleapis.com"
#   ]
#   shared_vpc_host_config = {
#     enabled = true
#   }
#   #metric_scopes = [module.net-project.project_id]
#   # optionally delegate a fixed set of IAM roles to selected principals
#   iam = {
#     (var.custom_roles.project_iam_viewer) = try(local.iam_viewer_principals["dev"], [])
#   }
#   iam_bindings = (
#     lookup(local.iam_delegated_principals, "dev", null) == null ? {} : {
#       sa_delegated_grants = {
#         role    = "roles/resourcemanager.projectIamAdmin"
#         members = try(local.iam_delegated_principals["dev"], [])
#         condition = {
#           title       = "dev_stage3_sa_delegated_grants"
#           description = "${var.environments["dev"].name} host project delegated grants."
#           expression = format(
#             "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
#             local.iam_delegated
#           )
#         }
#       }
#     }
#   )
#   tag_bindings = local.has_env_folders ? {} : {
#     environment = local.env_tag_values["dev"]
#   }
# }

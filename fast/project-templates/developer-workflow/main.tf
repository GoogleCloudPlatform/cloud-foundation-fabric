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

locals {
  config = yamldecode(file(var.data_file))
  features = try(local.config.features, {
    cloud_run = false
    firebase  = false
  })
  groups = try(local.config.groups, {
    approvers  = []
    developers = []
  })
  project_config = try(local.config.project_config, {
    dev  = {}
    qa   = {}
    prod = {}
  })
  folder_configs   = try(local.config.folders, {})
  project_services = try(local.config.project_services, [])

  envs = {
    for k, v in try(local.config.roles, {}) : k => v
  }
  services = distinct(local.project_services)
}


module "project" {
  source          = "../../../modules/project"
  for_each        = local.envs
  billing_account = var.billing_account.id
  name = coalesce(
    try(local.project_config[each.key].project_id, null),
  "${var.prefix}-${each.key}${try(local.project_config[each.key].app_name, "") == "" ? "" : "-${local.project_config[each.key].app_name}"}")
  parent   = "organizations/${var.organization.id}"
  services = local.services
  labels   = try(local.project_config[each.key].labels, {})

  iam = {
    for role in distinct(concat(try(each.value.developers, []), try(each.value.approvers, []))) :
    role => concat(
      contains(try(each.value.developers, []), role) ? ["group:${local.groups.developers[0]}"] : [],
      contains(try(each.value.approvers, []), role) ? ["group:${local.groups.approvers[0]}"] : []
    )
  }
  shared_vpc_service_config = try(local.project_config[each.key].shared_vpc_service_config, { host_project = null })
}

module "folder" {
  source   = "../../../modules/folder" # Assuming the folder module is located here
  for_each = local.folder_configs
  parent   = coalesce(try(each.value.parent, null), "organizations/${var.organization.id}")
  name     = "${var.prefix}-${each.value.name}" # Apply the global prefix to folder names
  iam      = try(each.value.iam, {})
  # Add other relevant folder variables here if needed, e.g., tag_bindings, asset_feeds, etc.
}

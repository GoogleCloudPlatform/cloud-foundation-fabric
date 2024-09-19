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

locals {
  _top_level_path = try(
    pathexpand(var.factories_config.top_level_folders), null
  )
  _top_level_files = try(
    fileset(local._top_level_path, "**/*.yaml"),
    []
  )
  _top_level_folders = {
    for f in local._top_level_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._top_level_path, "-")}/${f}"
    ))
  }
  top_level_automation = {
    for k, v in local.top_level_folders :
    k => v.automation if try(v.automation.enable, null) == true
  }
  top_level_folders = merge(
    {
      for k, v in local._top_level_folders : k => merge(v, {
        name = try(v.name, k)
        automation = try(v.automation, {
          enable                      = true
          sa_impersonation_principals = []
        })
        contacts              = try(v.contacts, {})
        firewall_policy       = try(v.firewall_policy, null)
        logging_data_access   = try(v.logging_data_access, {})
        logging_exclusions    = try(v.logging_exclusions, {})
        logging_settings      = try(v.logging_settings, null)
        logging_sinks         = try(v.logging_sinks, {})
        iam                   = try(v.iam, {})
        iam_bindings          = try(v.iam_bindings, {})
        iam_bindings_additive = try(v.iam_bindings_additive, {})
        iam_by_principals     = try(v.iam_by_principals, {})
        org_policies          = try(v.org_policies, {})
        tag_bindings          = try(v.tag_bindings, {})
      })
    },
    var.top_level_folders
  )
  top_level_sa = {
    for k, v in local.branch_service_accounts :
    k => "serviceAccount:${v}" if v != null
  }
  top_level_tags = {
    for k, v in try(local.tag_values, {}) : k => v.id
  }
}

module "top-level-folder" {
  source              = "../../../modules/folder"
  for_each            = local.top_level_folders
  parent              = local.root_node
  name                = each.value.name
  contacts            = each.value.contacts
  firewall_policy     = each.value.firewall_policy
  logging_data_access = each.value.logging_data_access
  logging_exclusions  = each.value.logging_exclusions
  logging_settings    = each.value.logging_settings
  logging_sinks       = each.value.logging_sinks
  iam = {
    for role, members in each.value.iam :
    lookup(var.custom_roles, role, role) => [
      for member in members : lookup(local.top_level_sa, member, member)
    ]
  }
  iam_bindings = {
    for k, v in each.value.iam_bindings : k => merge(v, {
      member = lookup(local.top_level_sa, v.member, v.member)
      role   = lookup(var.custom_roles, v.role, v.role)
    })
  }
  iam_bindings_additive = {
    for k, v in each.value.iam_bindings_additive : k => merge(v, {
      member = lookup(local.top_level_sa, v.member, v.member)
      role   = lookup(var.custom_roles, v.role, v.role)
    })
  }
  # we don't replace here to avoid dynamic values in keys
  iam_by_principals = each.value.iam_by_principals
  org_policies      = each.value.org_policies
  tag_bindings = {
    for k, v in each.value.tag_bindings : k => lookup(
      local.top_level_tags, v, v
    )
  }
}

module "top-level-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.top_level_automation
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-0"
  display_name = "Terraform resman ${each.key} folder service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = each.value.sa_impersonation_principals
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "top-level-bucket" {
  source     = "../../../modules/gcs"
  for_each   = local.top_level_automation
  project_id = var.automation.project_id
  name       = "prod-resman-${each.key}-0"
  prefix     = var.prefix
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.top-level-sa[each.key].iam_email]
    "roles/storage.objectViewer" = [module.top-level-sa[each.key].iam_email]
  }
}

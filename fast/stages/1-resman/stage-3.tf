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
  # read and decode factory files
  _stage3_path = try(
    pathexpand(var.factories_config.stage_3), null
  )
  _stage3_files = try(
    fileset(local._stage3_path, "**/*.yaml"),
    []
  )
  _stage3_data = {
    for f in local._stage3_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._stage3_path, "-")}/${f}"
    ))
  }
  # merge stage 3 from factory and variable data
  _stage3 = merge(
    # normalize factory data attributes with defaults and nulls
    {
      for k, v in local._stage3_data : k => {
        short_name  = v.short_name
        environment = try(v.environment, "dev")
        cicd_config = lookup(v, "cicd_config", null) == null ? null : {
          identity_provider = v.cicd_config.identity_provider
          repository = merge(v.cicd_config.repository, {
            branch = try(v.cicd_config.repository.branch, null)
            type   = try(v.cicd_config.repository.type, "github")
          })
          workflows_config = {
            extra_files = try(v.cicd_config.workflows_config.extra_files, [])
          }
        }
        folder_config = lookup(v, "folder_config", null) == null ? null : {
          name                  = v.folder_config.name
          iam                   = try(v.folder_config.iam, {})
          iam_bindings          = try(v.folder_config.iam_bindings, {})
          iam_bindings_additive = try(v.folder_config.iam_bindings_additive, {})
          iam_by_principals     = try(v.folder_config.iam_by_principals, {})
          org_policies          = try(v.folder_config.org_policies, {})
          parent_id             = try(v.folder_config.parent_id, null)
          tag_bindings          = try(v.folder_config.tag_bindings, {})
        }
      }
    },
    var.fast_stage_3
  )
  # normalize attributes
  stage3 = {
    for k, v in local._stage3 : k => merge(v, {
      short_name = replace(coalesce(v.short_name, k), "_", "-")
      # this code is identical to the one used for stage 2s
      folder_config = v.folder_config == null ? null : merge(v.folder_config, {
        iam = {
          for kk, vv in v.folder_config.iam : kk => [
            for m in vv : contains(["ro", "rw"], m) ? "${k}-${m}" : m
          ]
        }
        iam_bindings = {
          for kk, vv in v.folder_config.iam_bindings :
          kk => {
            role = vv.role
            members = [
              for m in vv.members : contains(["ro", "rw"], m) ? "${k}-${m}" : m
            ]
            condition = vv.condition == null ? null : {
              title = vv.condition.title
              expression = templatestring(vv.condition.expression, {
                custom_roles = var.custom_roles
                organization = var.organization
                tag_names    = var.tag_names
                tag_root     = local.tag_root
              })
              description = lookup(vv.condition, "description", null)
            }
          }
        }
        iam_bindings_additive = {
          for kk, vv in v.folder_config.iam_bindings_additive :
          kk => {
            role   = vv.role
            member = contains(["ro", "rw"], vv.member) ? "${k}-${vv.member}" : vv.member
            condition = vv.condition == null ? null : {
              title = vv.condition.title
              expression = templatestring(vv.condition.expression, {
                custom_roles = var.custom_roles
                organization = var.organization
                tag_names    = var.tag_names
                tag_root     = local.tag_root
              })
              description = lookup(vv.condition, "description", null)
            }
          }
        }
      })
    })
    if !contains(
      local.stage2_shortnames, replace(coalesce(v.short_name, k), "_", "-")
    )
  }
}

check "stage_short_names" {
  assert {
    condition = alltrue([
      for k, v in local._stage3 : !contains(
        local.stage2_shortnames, replace(coalesce(v.short_name, k), "_", "-")
      )
    ])
    error_message = "Some stage 3 short names overlap stage 2."
  }
}

# top-level folder

module "stage3-folder" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.stage3 : k => v if v.folder_config != null
  }
  parent = (
    each.value.folder_config.parent_id == null
    ? local.root_node
    : try(
      local.top_level_folder_ids[each.value.folder_config.parent_id],
      module.stage2-folder[each.value.folder_config.parent_id].id,
      each.value.folder_config.parent_id
    )
  )
  name = each.value.folder_config.name
  iam = {
    "roles/logging.admin"                  = [module.stage3-sa-rw[each.key].iam_email]
    "roles/owner"                          = [module.stage3-sa-rw[each.key].iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.stage3-sa-rw[each.key].iam_email]
    "roles/resourcemanager.projectCreator" = [module.stage3-sa-rw[each.key].iam_email]
    "roles/compute.xpnAdmin"               = [module.stage3-sa-rw[each.key].iam_email]
    "roles/viewer"                         = [module.stage3-sa-ro[each.key].iam_email]
    "roles/resourcemanager.folderViewer"   = [module.stage3-sa-ro[each.key].iam_email]

  }
  iam_by_principals = each.value.folder_config.iam_by_principals
  org_policies      = each.value.folder_config.org_policies
  tag_bindings = merge(
    {
      (var.tag_names.environment) = local.tag_values["${var.tag_names.environment}/${var.environments[each.value.environment].tag_name}"].id
    },
    {
      for k, v in each.value.folder_config.tag_bindings : k => try(
        local.tag_values[v].id, v
      )
    }
  )
  depends_on = [module.top-level-folder]
}

# automation service accounts

module "stage3-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.stage3
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-stage3_rw"], {
    name = each.value.short_name
  })
  display_name = (
    "Terraform resman ${each.key} service account."
  )
  prefix = "${var.prefix}-${var.environments[each.value.environment].short_name}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw[each.key].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "stage3-sa-ro" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.stage3
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["sa-stage3_ro"], {
    name = each.value.short_name
  })
  display_name = (
    "Terraform resman ${each.key} service account (read-only)."
  )
  prefix = "${var.prefix}-${each.value.environment}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro[each.key].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket

module "stage3-bucket" {
  source     = "../../../modules/gcs"
  for_each   = local.stage3
  project_id = var.automation.project_id
  name = templatestring(var.resource_names["gcs-stage3"], {
    name = each.value.short_name
  })
  prefix     = "${var.prefix}-${each.value.environment}"
  location   = var.locations.gcs
  versioning = true
  iam = {
    "roles/storage.objectAdmin"  = [module.stage3-sa-rw[each.key].iam_email]
    "roles/storage.objectViewer" = [module.stage3-sa-ro[each.key].iam_email]
  }
}

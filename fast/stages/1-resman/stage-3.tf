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
  _stage3_path = try(
    pathexpand(var.factories_config.stage_3), null
  )
  _stage3_files = try(
    fileset(local._stage3_path, "**/*.yaml"),
    []
  )
  _stage3 = {
    for f in local._stage3_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._stage3_path, "-")}/${f}"
    ))
  }
  stage3 = merge({
    for k, v in local._stage3 : k => {
      short_name  = v.short_name
      environment = try(v.environment, "dev")
      cicd_config = lookup(v, "cicd_config", null) == null ? null : {
        identity_provider = v.cicd_config.identity_provider
        repository = merge(v.cicd_config.repository, {
          branch = try(v.cicd_config.repository.branch, null)
          type   = try(v.cicd_config.repository.type, "github")
        })
      }
      folder_config = lookup(v, "folder_config", null) == null ? null : {
        name              = v.folder_config.name
        iam_by_principals = try(v.folder_config.iam_by_principals, {})
        parent_id         = try(v.folder_config.parent_id, null)
        tag_bindings      = try(v.folder_config.tag_bindings, {})
      }
      organization_iam = lookup(v, "organization_iam", null) == null ? null : {
        context_tag_value = v.organization_iam.context_tag_value
        sa_roles          = merge({ ro = [], rw = [] }, v.organization_iam.sa_roles)
      }
      stage2_iam = {
        networking = {
          iam_admin_delegated = try(
            v.stage2_iam.networking.iam_admin_delegated, false
          )
          sa_roles = merge(
            { ro = [], rw = [] }, try(v.stage2_iam.networking.sa_roles, {})
          )
        }
        security = {
          iam_admin_delegated = try(
            v.stage2_iam.security.iam_admin_delegated, false
          )
          sa_roles = merge(
            { ro = [], rw = [] }, try(v.stage2_iam.security.sa_roles, {})
          )
        }
      }
    }
  }, var.fast_stage_3)
  stage3_sa_roles_in_org = flatten([
    for k, v in local.stage3 : [
      for sa, roles in try(v.organization_iam.sa_roles, []) : [
        for role in roles : {
          context = try(v.organization_iam.context_tag_value, "")
          env     = var.environment_names[v.environment]
          role    = role
          sa      = sa
          s3      = k
        }
      ]
    ]
  ])
  stage3_iam_in_stage2 = flatten([
    for k, v in local.stage3 : [
      for s2, attrs in v.stage2_iam : [
        for sa, roles in attrs.sa_roles : [
          for role in roles : {
            env  = var.environment_names[v.environment]
            role = lookup(var.custom_roles, role, role)
            sa   = sa
            s2   = s2
            s3   = k
          }
        ]
      ]
    ]
  ])
  stage3_shortnames = distinct([for k, v in local.stage3 : v.short_name])
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
  tag_bindings = merge(
    {
      environment = local.tag_values["environment/${var.environment_names[each.value.environment]}"].id
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
  name       = "resman-${each.value.short_name}-0"
  display_name = (
    "Terraform resman ${each.key} service account."
  )
  prefix = "${var.prefix}-${each.value.environment}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw["${each.key}-prod"].iam_email, null)
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
  name       = "resman-${each.value.short_name}-0r"
  display_name = (
    "Terraform resman ${each.key} service account (read-only)."
  )
  prefix = "${var.prefix}-${each.value.environment}"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro["${each.key}-prod"].iam_email, null)
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
  source        = "../../../modules/gcs"
  for_each      = local.stage3
  project_id    = var.automation.project_id
  name          = "resman-${each.value.short_name}-0"
  prefix        = "${var.prefix}-${each.value.environment}"
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.stage3-sa-rw[each.key].iam_email]
    "roles/storage.objectViewer" = [module.stage3-sa-ro[each.key].iam_email]
  }
}

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
  stage3_sa_roles_in_org = flatten([
    for k, v in var.fast_stage_3 : [
      for sa, roles in v.organization_iam_roles : [
        for r in roles : { role = r, sa = sa, s3 = k }
      ]
    ]
  ])
  # TODO: this would be better and more narrowly handled from stage 2 projects
  stage3_sa_roles_in_stage2 = flatten([
    for k, v in var.fast_stage_3 : [
      for s2, attrs in v.stage2_iam_roles : [
        for sa, roles in attrs : [
          for role in roles : { role = role, sa = sa, s2 = s2, s3 = k }
        ]
      ]
    ]
  ])
}

# top-level folder

module "stage3-folder" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in var.fast_stage_3 : k => v if v.folder_config != null
  }
  parent = (
    each.value.folder_config.parent_id == null
    ? local.root_node
    : try(
      module.top-level-folder[each.value.folder_config.parent_id],
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
  tag_bindings = {
    for k, v in each.value.folder_config.tag_bindings : k => lookup(
      local.top_level_tags, v, v
    )
  }
  depends_on = [module.top-level-folder]
}

# automation service accounts

module "stage3-sa-rw" {
  source     = "../../../modules/iam-service-account"
  for_each   = var.fast_stage_3
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
  for_each   = var.fast_stage_3
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
  for_each      = var.fast_stage_3
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

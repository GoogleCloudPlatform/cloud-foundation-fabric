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
  stage3_folders_create = {
    for k, v in var.fast_stage_3 : k => v if v.folder_config != null
  }
  stage3_iam_roles = {
    rw = [
      "roles/logging.admin",
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/compute.xpnAdmin"
    ]
    ro = [
      "roles/viewer",
      "roles/resourcemanager.folderViewer"
    ]
  }
  stage3_sa_roles_in_org = flatten([
    for k, v in var.fast_stage_3 : [
      [
        for sa, roles in v.organization_iam_roles : [
          for r in roles : [
            [
              { env = "prod", role = r, sa = sa, s3 = k }
            ],
            v.folder_config.create_env_folders != true ? [] : [
              { env = "dev", role = r, sa = sa, s3 = k }
            ]
          ]
        ]
      ]
    ]
  ])
  # TODO: this would be better and more narrowly handled from stage 2 projects
  stage3_sa_roles_in_stage2 = flatten([
    for k, v in var.fast_stage_3 : [
      for s2, attrs in v.stage2_iam_roles : [
        for sa, roles in attrs : [
          for role in roles : [
            [
              { env = "prod", role = role, sa = sa, s2 = s2, s3 = k }
            ],
            v.folder_config.create_env_folders != true ? [] : [
              { env = "dev", role = role, sa = sa, s2 = s2, s3 = k }
            ]
          ]
        ]
      ]
    ]
  ])
}

module "stage3-folder" {
  source   = "../../../modules/folder"
  for_each = local.stage3_folders_create
  parent = (
    each.value.folder_config.parent_id == null
    ? local.root_node
    : each.value.folder_config.parent_id
  )
  name = each.value.folder_config.name
  iam = each.value.folder_config.create_env_folders == true ? {} : merge(
    {
      for r in local.stage3_iam_roles.rw :
      r => module.stage3-sa-prod-rw[each.key].iam_email
    },
    {
      for r in local.stage3_iam_roles.ro :
      r => module.stage3-sa-prod-ro[each.key].iam_email
    }
  )
  iam_by_principals = each.value.folder_config.iam_by_principals
  tag_bindings      = each.value.folder_config.tag_bindings
}

# optional per-environment folders

module "stage3-folder-prod" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.stage3_folders_create :
    k => v if v.folder_config.create_env_folders == true
  }
  parent = module.stage3-folder[each.key].id
  name   = "Production"
  iam = merge(
    {
      for r in local.stage3_iam_roles.rw :
      r => module.stage3-sa-prod-rw[each.key].iam_email
    },
    {
      for r in local.stage3_iam_roles.ro :
      r => module.stage3-sa-prod-ro[each.key].iam_email
    }
  )
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/production"].id,
      null
    )
  }
}

module "stage3-folder-dev" {
  source = "../../../modules/folder"
  for_each = {
    for k, v in local.stage3_folders_create :
    k => v if v.folder_config.create_env_folders == true
  }
  parent = module.stage3-folder[each.key].id
  name   = "Development"
  iam = merge(
    {
      for r in local.stage3_iam_roles.rw :
      r => module.stage3-sa-dev-rw[each.key].iam_email
    },
    {
      for r in local.stage3_iam_roles.ro :
      r => module.stage3-sa-dev-ro[each.key].iam_email
    }
  )
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

# automation service accounts (prod)

module "stage3-sa-prod-rw" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.stage3_folders_create
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-0"
  display_name = "Terraform resman ${each.key} service account."
  prefix       = var.prefix
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

module "stage3-sa-prod-ro" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.stage3_folders_create
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-0r"
  display_name = "Terraform resman ${each.key} service account (read-only)."
  prefix       = var.prefix
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

# automation bucket (prod)

module "stage3-bucket-prod" {
  source        = "../../../modules/gcs"
  for_each      = local.stage3_folders_create
  project_id    = var.automation.project_id
  name          = "prod-resman-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.stage3-sa-prod-rw[each.key].iam_email]
    "roles/storage.objectViewer" = [module.stage3-sa-prod-ro[each.key].iam_email]
  }
}

# automation service accounts (dev)

module "stage3-sa-dev-rw" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.stage3_folders_create :
    k => v if v.folder_config.create_env_folders == true
  }
  project_id   = var.automation.project_id
  name         = "dev-resman-${each.key}-0"
  display_name = "Terraform resman ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw["${each.key}-dev"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "stage3-sa-dev-ro" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.stage3_folders_create :
    k => v if v.folder_config.create_env_folders == true
  }
  project_id   = var.automation.project_id
  name         = "dev-resman-${each.key}-0r"
  display_name = "Terraform resman ${each.key} service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro["${each.key}-dev"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = [var.custom_roles["storage_viewer"]]
  }
}

# automation bucket (dev)

module "stage3-bucket-dev" {
  source = "../../../modules/gcs"
  for_each = {
    for k, v in local.stage3_folders_create :
    k => v if v.folder_config.create_env_folders == true
  }
  project_id    = var.automation.project_id
  name          = "dev-resman-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.stage3-sa-dev-rw[each.key].iam_email]
    "roles/storage.objectViewer" = [module.stage3-sa-dev-ro[each.key].iam_email]
  }
}

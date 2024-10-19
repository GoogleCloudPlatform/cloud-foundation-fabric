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
  sec_use_env_folders = (
    var.fast_stage_2.security.enabled &&
    var.fast_stage_2.security.folder_config.create_env_folders
  )
  sec_s3_iam = !var.fast_stage_2.security.enabled ? {} : {
    for v in local.stage3_iam_in_stage2 : "${v.role}:${v.env}" => (
      v.sa == "rw"
      ? module.stage3-sa-rw[v.s3].iam_email
      : module.stage3-sa-ro[v.s3].iam_email
    )...
    if v.s2 == "security"
  }
}

# top-level folder

module "sec-folder" {
  source = "../../../modules/folder"
  count  = var.fast_stage_2.security.enabled ? 1 : 0
  parent = (
    var.fast_stage_2.security.folder_config.parent_id == null
    ? local.root_node
    : try(
      local.top_level_folder_ids[var.fast_stage_2.security.folder_config],
      var.fast_stage_2.security.folder_config.parent_id
    )
  )
  name = var.fast_stage_2.security.folder_config.name
  iam = merge(
    # stage own service accounts
    {
      "roles/logging.admin"                  = [module.sec-sa-rw[0].iam_email]
      "roles/owner"                          = [module.sec-sa-rw[0].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.sec-sa-rw[0].iam_email]
      "roles/resourcemanager.projectCreator" = [module.sec-sa-rw[0].iam_email]
      "roles/resourcemanager.tagUser"        = [module.net-sa-rw[0].iam_email]
      "roles/viewer"                         = [module.sec-sa-ro[0].iam_email]
      "roles/resourcemanager.folderViewer"   = [module.sec-sa-ro[0].iam_email]
      "roles/resourcemanager.tagViewer"      = [module.net-sa-ro[0].iam_email]
    },
    # project factory service accounts
    (var.fast_stage_2.project_factory.enabled) != true ? {} : {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        module.pf-sa-rw[0].iam_email
      ]
      "roles/cloudkms.viewer" = [
        module.pf-sa-ro[0].iam_email
      ]
    }
  )
  iam_bindings = merge(
    var.fast_stage_2.project_factory.enabled != true ? {} : {
      pf_delegated_grant = {
        role    = "roles/resourcemanager.projectIamAdmin"
        members = [module.pf-sa-rw[0].iam_email]
        condition = {
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            "'roles/cloudkms.cryptoKeyEncrypterDecrypter'"
          )
          title       = "pf_delegated_grant"
          description = "Project factory delegated grant."
        }
      }
    },
    # stage 3 IAM bindings use conditions based on environment
    {
      for k, v in local.sec_s3_iam : k => {
        role    = split(":", k)[0]
        members = v
        condition = {
          title      = "stage 3 ${split(":", k)[1]}"
          expression = <<-END
            resource.matchTag(
              '${local.tag_root}/${var.tag_names.environment}',
              '${split(":", k)[1]}'
            )
          END
        }
      }
    }
  )
  iam_by_principals = merge(
    {
      # replace with more selective custom roles for production deployments
      (local.principals.gcp-security-admins) = ["roles/editor"]
    },
    var.fast_stage_2.security.folder_config.iam_by_principals
  )
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/security"].id, null
    )
  }
}

# optional per-environment folders

module "sec-folder-prod" {
  source = "../../../modules/folder"
  count  = local.sec_use_env_folders ? 1 : 0
  parent = module.sec-folder[0].id
  name   = title(var.environment_names["prod"])
  iam = {
    # stage 3s service accounts
    for role, attrs in local.sec_s3_iam.prod : role => [
      for v in attrs : (
        v.sa == "ro"
        ? module.stage3-sa-ro[v.s3].iam_email
        : module.stage3-sa-rw[v.s3].iam_email
      )
    ]
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/${var.environment_names["prod"]}"].id,
      null
    )
  }
}

module "sec-folder-dev" {
  source = "../../../modules/folder"
  count  = local.sec_use_env_folders ? 1 : 0
  parent = module.sec-folder[0].id
  name   = title(var.environment_names["dev"])
  iam = {
    # stage 3s service accounts
    for role, attrs in local.sec_s3_iam.dev : role => [
      for v in attrs : (
        v.sa == "ro"
        ? module.stage3-sa-ro[v.s3].iam_email
        : module.stage3-sa-rw[v.s3].iam_email
      )
    ]
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/${var.environment_names["dev"]}"].id,
      null
    )
  }
}

# automation service accounts

module "sec-sa-rw" {
  source                 = "../../../modules/iam-service-account"
  count                  = var.fast_stage_2.security.enabled ? 1 : 0
  project_id             = var.automation.project_id
  name                   = "prod-resman-${var.fast_stage_2.security.short_name}-0"
  display_name           = "Terraform resman security service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw["security"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "sec-sa-ro" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_stage_2.security.enabled ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-${var.fast_stage_2.security.short_name}-0r"
  display_name = "Terraform resman security service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro["security"].iam_email, null)
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

module "sec-bucket" {
  source        = "../../../modules/gcs"
  count         = var.fast_stage_2.security.enabled ? 1 : 0
  project_id    = var.automation.project_id
  name          = "prod-resman-${var.fast_stage_2.security.short_name}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.sec-sa-rw[0].iam_email]
    "roles/storage.objectViewer" = [module.sec-sa-ro[0].iam_email]
  }
}

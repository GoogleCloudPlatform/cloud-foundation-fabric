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
  net_use_env_folders = (
    var.fast_stage_2.networking.enabled &&
    var.fast_stage_2.networking.folder_config.create_env_folders
  )
  # TODO: this would be better and more narrowly handled from stage 2 projects
  net_stage3_iam = {
    dev = {
      for v in local.stage3_sa_roles_in_stage2 :
      lookup(var.custom_roles, v.role, v.role) => v...
      if v.env == "dev" && v.s2 == "networking"
    }
    prod = {
      for v in local.stage3_sa_roles_in_stage2 :
      lookup(var.custom_roles, v.role, v.role) => v...
      if v.env == "prod" && v.s2 == "networking"
    }
  }
}

# top-level folder

module "net-folder" {
  source = "../../../modules/folder"
  count  = var.fast_stage_2.networking.enabled ? 1 : 0
  parent = (
    var.fast_stage_2.networking.folder_config.parent_id == null
    ? local.root_node
    : var.fast_stage_2.networking.folder_config.parent_id
  )
  name = var.fast_stage_2.networking.folder_config.name
  iam = merge(
    # stage own service accounts
    {
      "roles/logging.admin"                  = [module.net-sa-rw[0].iam_email]
      "roles/owner"                          = [module.net-sa-rw[0].iam_email]
      "roles/resourcemanager.folderAdmin"    = [module.net-sa-rw[0].iam_email]
      "roles/resourcemanager.projectCreator" = [module.net-sa-rw[0].iam_email]
      "roles/compute.xpnAdmin"               = [module.net-sa-rw[0].iam_email]
      "roles/viewer"                         = [module.net-sa-ro[0].iam_email]
      "roles/resourcemanager.folderViewer"   = [module.net-sa-ro[0].iam_email]
    },
    # security stage 2 service accounts
    var.fast_stage_2.security.enabled != true ? {} : {
      "roles/serviceusage.serviceUsageAdmin" = [
        try(module.sec-sa-rw[0].iam_email, null)
      ]
      "roles/serviceusage.serviceUsageConsumer" = [
        try(module.sec-sa-ro[0].iam_email, null)
      ]
    },
    try(var.custom_roles["network_firewall_policies_admin"], null) == null ? {} : {
      (var.custom_roles["network_firewall_policies_admin"]) = [
        try(module.sec-sa-rw[0].iam_email, null)
      ]
    },
    try(var.custom_roles["network_firewall_policies_viewer"], null) == null ? {} : {
      (var.custom_roles["network_firewall_policies_viewer"]) = [
        try(module.sec-sa-ro[0].iam_email, null)
      ]
    },
    # stage 3s service accounts (if not using environment folders)
    var.fast_stage_2.networking.folder_config.create_env_folders == true ? {} : {
      for role, attrs in local.net_stage3_iam.prod : role => [
        for v in attrs : (
          v.sa == "ro"
          ? module.stage3-sa-ro[v.s3].iam_email
          : module.stage3-sa-rw[v.s3].iam_email
        )
      ]
    }
  )
  iam_by_principals = merge(
    # replace with more selective custom roles for production deployments
    { (local.principals.gcp-network-admins) = ["roles/editor"] },
    var.fast_stage_2.networking.folder_config.iam_by_principals
  )
  tag_bindings = {
    context = try(
      local.tag_values["${var.tag_names.context}/networking"].id, null
    )
  }
}

# optional per-environment folders

module "net-folder-prod" {
  source = "../../../modules/folder"
  count  = local.net_use_env_folders ? 1 : 0
  parent = module.net-folder[0].id
  name   = "Production"
  iam = {
    # stage 3s service accounts
    for role, attrs in local.net_stage3_iam.prod : role => [
      for v in attrs : (
        v.sa == "ro"
        ? module.stage3-sa-ro[v.s3].iam_email
        : module.stage3-sa-rw[v.s3].iam_email
      )
    ]
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/production"].id,
      null
    )
  }
}

module "net-folder-dev" {
  source = "../../../modules/folder"
  count  = local.net_use_env_folders ? 1 : 0
  parent = module.net-folder[0].id
  name   = "Development"
  iam = {
    # stage 3s service accounts
    for role, attrs in local.net_stage3_iam.dev : role => [
      for v in attrs : (
        v.sa == "ro"
        ? module.stage3-sa-ro[v.s3].iam_email
        : module.stage3-sa-rw[v.s3].iam_email
      )
    ]
  }
  tag_bindings = {
    environment = try(
      local.tag_values["${var.tag_names.environment}/development"].id,
      null
    )
  }
}

# automation service accounts

module "net-sa-rw" {
  source                 = "../../../modules/iam-service-account"
  count                  = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id             = var.automation.project_id
  name                   = "prod-resman-${var.fast_stage_2.networking.short_name}-0"
  display_name           = "Terraform resman networking service account."
  prefix                 = var.prefix
  service_account_create = var.root_node == null
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-rw["networking"].iam_email, null)
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "net-sa-ro" {
  source       = "../../../modules/iam-service-account"
  count        = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id   = var.automation.project_id
  name         = "prod-resman-${var.fast_stage_2.networking.short_name}-0r"
  display_name = "Terraform resman networking service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.cicd-sa-ro["networking"].iam_email, null)
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

module "net-bucket" {
  source        = "../../../modules/gcs"
  count         = var.fast_stage_2.networking.enabled ? 1 : 0
  project_id    = var.automation.project_id
  name          = "prod-resman-${var.fast_stage_2.networking.short_name}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.net-sa-rw[0].iam_email]
    "roles/storage.objectViewer" = [module.net-sa-ro[0].iam_email]
  }
}

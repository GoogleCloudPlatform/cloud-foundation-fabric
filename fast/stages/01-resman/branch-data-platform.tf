/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Data Platform stages resources.

locals {
  cicd_dp_prod = (
    contains(keys(var.cicd_config.repositories), "data_platform_prod")
    ? var.cicd_config.repositories.networking
    : null
  )
  cicd_dp_dev = (
    contains(keys(var.cicd_config.repositories), "data_platform_dev")
    ? var.cicd_config.repositories.networking
    : null
  )
}

module "branch-dp-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Data Platform"
  tag_bindings = {
    context = module.organization.tag_values["context/data"].id
  }
}

module "branch-dp-dev-folder" {
  source    = "../../../modules/folder"
  parent    = module.branch-dp-folder.id
  name      = "Development"
  group_iam = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = [module.branch-dp-dev-sa.iam_email]
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = [module.branch-dp-dev-sa.iam_email]
    "roles/logging.admin"                  = [module.branch-dp-dev-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-dp-dev-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-dp-dev-sa.iam_email]
  }
  tag_bindings = {
    context = module.organization.tag_values["environment/development"].id
  }
}

module "branch-dp-prod-folder" {
  source    = "../../../modules/folder"
  parent    = module.branch-dp-folder.id
  name      = "Production"
  group_iam = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = [module.branch-dp-prod-sa.iam_email]
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = [module.branch-dp-prod-sa.iam_email]
    "roles/logging.admin"                  = [module.branch-dp-prod-sa.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-dp-prod-sa.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-dp-prod-sa.iam_email]
  }
  tag_bindings = {
    context = module.organization.tag_values["environment/production"].id
  }
}

# automation service accounts and buckets

module "branch-dp-dev-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation.project_id
  name        = "dev-resman-dp-0"
  description = "Terraform Data Platform development service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-dp-dev-sa-cicd.0.iam_email, null)
    ])
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.admin"]
  }
}

module "branch-dp-prod-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation.project_id
  name        = "prod-resman-dp-0"
  description = "Terraform Data Platform production service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      try(module.branch-dp-prod-sa-cicd.0.iam_email, null)
    ])
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.admin"]
  }
}

module "branch-dp-dev-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "dev-resman-dp-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dp-dev-sa.iam_email]
  }
}

module "branch-dp-prod-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation.project_id
  name       = "prod-resman-dp-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-dp-prod-sa.iam_email]
  }
}

# ci/cd service accounts

module "branch-dp-dev-sa-cicd" {
  source      = "../../../modules/iam-service-account"
  count       = local.cicd_dp_dev == null ? 0 : 1
  project_id  = var.automation.project_id
  name        = "dev-resman-dp-1"
  description = "Terraform CI/CD Data Platform development service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      local.cicd_dp_dev.branch == null
      ? format(
        local.cicd_tpl_principalset,
        var.automation.wif_pool,
        local.cicd_dp_dev.name
      )
      : format(
        local.cicd_tpl_principal[local.cicd_dp_dev.provider],
        local.cicd_dp_dev.name,
        local.cicd_dp_dev.branch
      )
    ]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-dp-prod-sa-cicd" {
  source      = "../../../modules/iam-service-account"
  count       = local.cicd_dp_prod == null ? 0 : 1
  project_id  = var.automation.project_id
  name        = "prod-resman-dp-1"
  description = "Terraform CI/CD Data Platform production service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      local.cicd_dp_prod.branch == null
      ? format(
        local.cicd_tpl_principalset,
        var.automation.wif_pool,
        local.cicd_dp_prod.name
      )
      : format(
        local.cicd_tpl_principal[local.cicd_dp_prod.provider],
        local.cicd_dp_prod.name,
        local.cicd_dp_prod.branch
      )
    ]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

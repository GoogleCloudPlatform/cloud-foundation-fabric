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

module "branch-dp-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Data Platform"
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/data"].id, null
    )
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
    context = try(
      module.organization.tag_values["${var.tag_names.environment}/development"].id, null
    )
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
    context = try(
      module.organization.tag_values["${var.tag_names.environment}/production"].id, null
    )
  }
}

# automation service accounts and buckets

module "branch-dp-dev-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation.project_id
  name        = "dev-resman-dp-0"
  description = "Terraform data platform development service account."
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
  description = "Terraform data platform production service account."
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
  source = "../../../modules/iam-service-account"
  for_each = (
    lookup(local.cicd_repositories, "dp_dev", null) == null
    ? {}
    : { 0 = local.cicd_repositories.dp_dev }
  )
  project_id  = var.automation.project_id
  name        = "dev-resman-dp-1"
  description = "Terraform CI/CD data platform development service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principalset_tpl,
        each.value.name
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_tpl,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-dp-prod-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    lookup(local.cicd_repositories, "dp_prod", null) == null
    ? {}
    : { 0 = local.cicd_repositories.dp_prod }
  )
  project_id  = var.automation.project_id
  name        = "prod-resman-dp-1"
  description = "Terraform CI/CD data platform production service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principalset_tpl,
        var.automation.federated_identity_pool,
        each.value.name
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_tpl,
        var.automation.federated_identity_pool,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

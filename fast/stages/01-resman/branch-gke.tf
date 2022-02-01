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

# tfdoc:file:description Security stage resources.

# top-level gke folder and service account

module "branch-gke-folder" {
  source = "../../../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "GKE"
}

module "branch-gke-prod-sa" {
  source      = "../../../modules/iam-service-account"
  project_id  = var.automation_project_id
  name        = "resman-gke-0"
  description = "Terraform gke production service account."
  prefix      = local.prefixes.prod
}

# GKE-level folders, service accounts and buckets for each individual environment

module "branch-gke-envs-folder" {
  source    = "../../../modules/folder"
  for_each  = coalesce(var.gke_environments, {})
  parent    = module.branch-gke-folder.id
  name      = each.value.descriptive_name
  group_iam = each.value.group_iam == null ? {} : each.value.group_iam
}

module "branch-gke-env-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = coalesce(var.gke_environments, {})
  project_id  = var.automation_project_id
  name        = "gke-${each.key}-0"
  description = "Terraform env ${each.key} service account."
  prefix      = local.prefixes.prod
  iam = {
    "roles/iam.serviceAccountTokenCreator" = (
      each.value.impersonation_groups == null
      ? []
      : [for g in each.value.impersonation_groups : "group:${g}"]
    )
  }
}

module "branch-gke-env-gcs" {
  source     = "../../../modules/gcs"
  for_each   = coalesce(var.gke_environments, {})
  project_id = var.automation_project_id
  name       = "gke-${each.key}-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-env-sa[each.key].iam_email]
  }
}

# environment: dev folder automation resources

module "branch-gke-env-dev-folder" {
  source   = "../../../modules/folder"
  for_each = coalesce(var.gke_environments, {})
  parent   = module.branch-gke-envs-folder[each.key].id
  # naming: environment descriptive name
  name = "${module.branch-gke-envs-folder[each.key].name} - Dev"
  # environment-wide human permissions on the whole gke environment
  group_iam = {}
  iam = {
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/logging.admin" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
  }
}

module "branch-gke-env-dev-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.automation_project_id
  name       = "resman-gke-env-0"
  # naming: environment in description
  description = "Terraform gke multitenant production service account."
  prefix      = local.prefixes.dev
}

module "branch-gke-env-dev-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-gke-env-0"
  prefix     = local.prefixes.dev
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-env-prod-sa.iam_email]
  }
}



# environment: production folder automation resources

module "branch-gke-env-prod-folder" {
  source   = "../../../modules/folder"
  for_each = coalesce(var.gke_environments, {})
  parent   = module.branch-gke-envs-folder[each.key].id
  # naming: environment descriptive name
  name = "${module.branch-gke-envs-folder[each.key].name} - Production"
  # environment-wide human permissions on the whole gke environment
  group_iam = {}
  iam = {
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/logging.admin" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/resourcemanager.folderAdmin" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
    "roles/resourcemanager.projectCreator" = [
      module.branch-gke-env-prod-sa.iam_email
    ]
  }
}

module "branch-gke-env-prod-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = var.automation_project_id
  name       = "resman-gke-env-0"
  # naming: environment in description
  description = "Terraform gke multitenant production service account."
  prefix      = local.prefixes.prod
}

module "branch-gke-env-prod-gcs" {
  source     = "../../../modules/gcs"
  project_id = var.automation_project_id
  name       = "resman-gke-env-0"
  prefix     = local.prefixes.prod
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-gke-env-prod-sa.iam_email]
  }
}

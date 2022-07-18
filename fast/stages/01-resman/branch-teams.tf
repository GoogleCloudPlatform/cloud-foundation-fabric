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

# tfdoc:file:description Team stage resources.

moved {
  from = module.branch-teams-folder
  to   = module.branch-teams-folder.0
}

module "branch-teams-folder" {
  source = "../../../modules/folder"
  count  = var.fast_features.teams ? 1 : 0
  parent = "organizations/${var.organization.id}"
  name   = "Teams"
  tag_bindings = {
    context = try(
      module.organization.tag_values["${var.tag_names.context}/teams"].id, null
    )
  }
}

moved {
  from = module.branch-teams-prod-sa
  to   = module.branch-teams-prod-sa.0
}

module "branch-teams-prod-sa" {
  source      = "../../../modules/iam-service-account"
  count       = var.fast_features.teams ? 1 : 0
  project_id  = var.automation.project_id
  name        = "prod-resman-teams-0"
  description = "Terraform resman production service account."
  prefix      = var.prefix
}

# Team-level folders, service accounts and buckets for each individual team

module "branch-teams-team-folder" {
  source    = "../../../modules/folder"
  for_each  = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent    = module.branch-teams-folder.0.id
  name      = each.value.descriptive_name
  group_iam = each.value.group_iam == null ? {} : each.value.group_iam
}

module "branch-teams-team-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id  = var.automation.project_id
  name        = "prod-teams-${each.key}-0"
  description = "Terraform team ${each.key} service account."
  prefix      = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = (
      each.value.impersonation_groups == null
      ? []
      : [for g in each.value.impersonation_groups : "group:${g}"]
    )
  }
}

module "branch-teams-team-gcs" {
  source     = "../../../modules/gcs"
  for_each   = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  project_id = var.automation.project_id
  name       = "prod-teams-${each.key}-0"
  prefix     = var.prefix
  versioning = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-teams-team-sa[each.key].iam_email]
  }
}

# project factory per-team environment folders

module "branch-teams-team-dev-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-teams-team-folder[each.key].id
  # naming: environment descriptive name
  name = "Development"
  # environment-wide human permissions on the whole teams environment
  group_iam = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = [module.branch-pf-dev-sa.0.iam_email]
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = [module.branch-pf-dev-sa.0.iam_email]
    "roles/logging.admin"                  = [module.branch-pf-dev-sa.0.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-pf-dev-sa.0.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-pf-dev-sa.0.iam_email]
  }
  tag_bindings = {
    environment = try(
      module.organization.tag_values["${var.tag_names.environment}/development"].id, null
    )
  }
}

module "branch-teams-team-prod-folder" {
  source   = "../../../modules/folder"
  for_each = var.fast_features.teams ? coalesce(var.team_folders, {}) : {}
  parent   = module.branch-teams-team-folder[each.key].id
  # naming: environment descriptive name
  name = "Production"
  # environment-wide human permissions on the whole teams environment
  group_iam = {}
  iam = {
    (local.custom_roles.service_project_network_admin) = [module.branch-pf-prod-sa.0.iam_email]
    # remove owner here and at project level if SA does not manage project resources
    "roles/owner"                          = [module.branch-pf-prod-sa.0.iam_email]
    "roles/logging.admin"                  = [module.branch-pf-prod-sa.0.iam_email]
    "roles/resourcemanager.folderAdmin"    = [module.branch-pf-prod-sa.0.iam_email]
    "roles/resourcemanager.projectCreator" = [module.branch-pf-prod-sa.0.iam_email]
  }
  tag_bindings = {
    environment = try(
      module.organization.tag_values["${var.tag_names.environment}/production"].id, null
    )
  }
}

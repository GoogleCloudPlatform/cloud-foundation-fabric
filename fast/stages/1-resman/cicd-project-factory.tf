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

# tfdoc:file:description CI/CD resources for the project factories.

# read-write (apply) SAs used by CI/CD workflows to impersonate automation SAs

module "branch-pf-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "pf-resman-pf-1"
  display_name = "Terraform CI/CD project factory main service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
      : length(regexall("%s", local.identity_providers[each.value.identity_provider].principal_branch)) == 2
      ? format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.branch
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-pf-dev-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory_dev.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory_dev }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "dev-pf-resman-pf-1"
  display_name = "Terraform CI/CD project factory development service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
      : length(regexall("%s", local.identity_providers[each.value.identity_provider].principal_branch)) == 2
      ? format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.branch
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-pf-prod-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory_prod.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory_prod }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "prod-pf-resman-pf-1"
  display_name = "Terraform CI/CD project factory production service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
      : length(regexall("%s", local.identity_providers[each.value.identity_provider].principal_branch)) == 2
      ? format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.branch
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

# read-only (plan) SAs used by CI/CD workflows to impersonate automation SAs

module "branch-pf-r-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "resman-pf-1r"
  display_name = "Terraform CI/CD project factory main service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-pf-dev-r-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory_dev.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory_dev }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "dev-resman-pf-1r"
  display_name = "Terraform CI/CD project factory development service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-pf-prod-r-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.project_factory_prod.name, null) != null
    ? { 0 = local.cicd_repositories.project_factory_prod }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "prod-resman-pf-1r"
  display_name = "Terraform CI/CD project factory production service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

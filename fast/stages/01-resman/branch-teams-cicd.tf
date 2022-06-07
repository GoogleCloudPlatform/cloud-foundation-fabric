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

locals {
  cicd_pf_multirepo = length(toset(compact([
    try(local.cicd_repositories.project_factory_dev.name, null),
    try(local.cicd_repositories.project_factory_prod.name, null)
  ]))) == 2
}

# source repos

resource "google_sourcerepo_repository" "pf_prod" {
  for_each = (
    try(local.cicd_repositories.project_factory_prod.type, null) == "sourcerepo"
    ? { 0 = 0 }
    : {}
  )
  project = var.automation.project_id
  name    = local.cicd_repositories.project_factory_prod.name
}

resource "google_sourcerepo_repository" "pf_dev" {
  for_each = (
    try(local.cicd_repositories.project_factory_dev.type, null) == "sourcerepo"
    &&
    local.cicd_pf_multirepo
    ? { 0 = 0 }
    : {}
  )
  project = var.automation.project_id
  name    = local.cicd_repositories.project_factory_dev.name
}

# source repo triggers

resource "google_cloudbuild_trigger" "pf_prod" {
  for_each = {
    for k, v in google_sourcerepo_repository.pf_prod : k => v.name
  }
  project        = var.automation.project_id
  name           = "fast-02-pf-prod"
  included_files = ["**/*tf", ".cloudbuild/workflow.yaml"]
  trigger_template {
    project_id  = var.automation.project_id
    branch_name = local.cicd_repositories.project_factory_prod.branch
    repo_name   = each.value.name
  }
  service_account = module.branch-teams-prod-pf-sa-cicd.0.id
  filename        = ".cloudbuild/workflow.yaml"
}

resource "google_cloudbuild_trigger" "pf_dev" {
  for_each = (
    local.cicd_pf_multirepo
    ? {
      for k, v in google_sourcerepo_repository.pf_dev : k => v.name
    }
    : {
      for k, v in google_sourcerepo_repository.pf_prod : k => v.name
    }
  )
  project        = var.automation.project_id
  name           = "fast-02-pf-prod"
  included_files = ["**/*tf", ".cloudbuild/workflow.yaml"]
  trigger_template {
    project_id  = var.automation.project_id
    branch_name = local.cicd_repositories.project_factory_dev.branch
    repo_name   = each.value.name
  }
  service_account = module.branch-teams-dev-pf-sa-cicd.0.id
  filename        = ".cloudbuild/workflow.yaml"
}

# source repo role to allow control to whoever can impersonate the automation SA

resource "google_sourcerepo_repository_iam_member" "pf_prod_admin" {
  for_each = {
    for k, v in google_sourcerepo_repository.pf_prod : k => v.name
  }
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.admin"
  member     = module.branch-teams-prod-pf-sa.iam_email
}

resource "google_sourcerepo_repository_iam_member" "pf_dev_admin" {
  for_each = (
    local.cicd_pf_multirepo
    ? {
      for k, v in google_sourcerepo_repository.pf_dev : k => v.name
    }
    : {
      for k, v in google_sourcerepo_repository.pf_prod : k => v.name
    }
  )
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.admin"
  member     = module.branch-teams-dev-pf-sa.iam_email
}

# source repo role to allow read access to the CI/CD SA

resource "google_sourcerepo_repository_iam_member" "pf_prod_reader" {
  for_each = {
    for k, v in google_sourcerepo_repository.pf_prod : k => v.name
  }
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.reader"
  member     = module.branch-teams-prod-pf-sa-cicd.0.iam_email
}

resource "google_sourcerepo_repository_iam_member" "pf_dev_reader" {
  for_each = (
    local.cicd_pf_multirepo
    ? {
      for k, v in google_sourcerepo_repository.pf_dev : k => v.name
    }
    : {
      for k, v in google_sourcerepo_repository.pf_prod : k => v.name
    }
  )
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.reader"
  member     = module.branch-teams-dev-pf-sa-cicd.0.iam_email
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "branch-teams-dev-pf-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    lookup(local.cicd_repositories, "pf_dev", null) == null
    ? {}
    : { 0 = local.cicd_repositories.pf_dev }
  )
  project_id  = var.automation.project_id
  name        = "dev-resman-pf-1"
  description = "Terraform CI/CD project factory development service account."
  prefix      = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
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
  )
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "branch-teams-prod-pf-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    lookup(local.cicd_repositories, "pf_prod", null) == null
    ? {}
    : { 0 = local.cicd_repositories.pf_prod }
  )
  project_id  = var.automation.project_id
  name        = "prod-resman-pf-1"
  description = "Terraform CI/CD project factory production service account."
  prefix      = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
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
  )
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

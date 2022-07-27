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

# tfdoc:file:description CI/CD resources for the data platform branch.

# source repositories

module "branch-dp-dev-cicd-repo" {
  source = "../../../modules/source-repository"
  for_each = (
    try(local.cicd_repositories.data_platform_dev.type, null) == "sourcerepo"
    ? { 0 = local.cicd_repositories.data_platform_dev }
    : {}
  )
  project_id = var.automation.project_id
  name       = each.value.name
  iam = {
    "roles/source.admin" = compact([
      try(module.branch-dp-dev-sa.0.iam_email, "")
    ])
    "roles/source.reader" = compact([
      try(module.branch-dp-dev-sa-cicd.0.iam_email, "")
    ])
  }
  triggers = {
    fast-03-dp-dev = {
      filename = ".cloudbuild/workflow.yaml"
      included_files = [
        "**/*json", "**/*tf", "**/*yaml", ".cloudbuild/workflow.yaml"
      ]
      service_account = module.branch-dp-dev-sa-cicd.0.id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.branch
        repo_name   = each.value.name
        tag_name    = null
      }
    }
  }
  depends_on = [module.branch-dp-dev-sa-cicd]
}

module "branch-dp-prod-cicd-repo" {
  source = "../../../modules/source-repository"
  for_each = (
    try(local.cicd_repositories.data_platform_prod.type, null) == "sourcerepo"
    ? { 0 = local.cicd_repositories.data_platform_prod }
    : {}
  )
  project_id = var.automation.project_id
  name       = each.value.name
  iam = {
    "roles/source.admin"  = [module.branch-dp-prod-sa.0.iam_email]
    "roles/source.reader" = [module.branch-dp-prod-sa-cicd.0.iam_email]
  }
  triggers = {
    fast-03-dp-prod = {
      filename = ".cloudbuild/workflow.yaml"
      included_files = [
        "**/*json", "**/*tf", "**/*yaml", ".cloudbuild/workflow.yaml"
      ]
      service_account = module.branch-dp-prod-sa-cicd.0.id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.branch
        repo_name   = each.value.name
        tag_name    = null
      }
    }
  }
  depends_on = [module.branch-dp-prod-sa-cicd]
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "branch-dp-dev-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.data_platform_dev.name, null) != null
    ? { 0 = local.cicd_repositories.data_platform_dev }
    : {}
  )
  project_id  = var.automation.project_id
  name        = "dev-resman-dp-1"
  description = "Terraform CI/CD data platform development service account."
  prefix      = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {
      "roles/iam.serviceAccountUser" = local.automation_resman_sa
    }
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

module "branch-dp-prod-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.data_platform_prod.name, null) != null
    ? { 0 = local.cicd_repositories.data_platform_prod }
    : {}
  )
  project_id  = var.automation.project_id
  name        = "prod-resman-dp-1"
  description = "Terraform CI/CD data platform production service account."
  prefix      = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {
      "roles/iam.serviceAccountUser" = local.automation_resman_sa
    }
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

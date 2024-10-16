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

# tfdoc:file:description CI/CD resources for the security branch.

# read-write (apply) SA used by CI/CD workflows to impersonate automation SA

module "branch-security-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.security.name, null) != null
    ? { 0 = local.cicd_repositories.security }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "prod-resman-sec-1"
  display_name = "Terraform CI/CD stage 2 security service account."
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

# read-only (plan) SA used by CI/CD workflows to impersonate automation SA

module "branch-security-r-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    try(local.cicd_repositories.security.name, null) != null
    ? { 0 = local.cicd_repositories.security }
    : {}
  )
  project_id   = var.automation.project_id
  name         = "prod-resman-sec-1r"
  display_name = "Terraform CI/CD stage 2 security service account (read-only)."
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

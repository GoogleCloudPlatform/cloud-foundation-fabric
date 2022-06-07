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

# source repo

resource "google_sourcerepo_repository" "networking" {
  for_each = (
    try(local.cicd_repositories.networking.type, null) == "sourcerepo"
    ? { 0 = 0 }
    : {}
  )
  project = var.automation.project_id
  name    = local.cicd_repositories.networking.name
}

# source repo trigger

resource "google_cloudbuild_trigger" "networking" {
  for_each = {
    for k, v in google_sourcerepo_repository.networking : k => v.name
  }
  project        = var.automation.project_id
  name           = "fast-02-networking"
  included_files = ["**/*tf", "**/*yaml", "**/*json", ".cloudbuild/workflow.yaml"]
  trigger_template {
    project_id  = var.automation.project_id
    branch_name = local.cicd_repositories.networking.branch
    repo_name   = each.value.name
  }
  service_account = module.branch-network-sa-cicd.0.id
  filename        = ".cloudbuild/workflow.yaml"
}

# source repo role to allow control to whoever can impersonate the automation SA

resource "google_sourcerepo_repository_iam_member" "networking_admin" {
  for_each = {
    for k, v in google_sourcerepo_repository.networking : k => v.name
  }
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.admin"
  member     = module.branch-network-sa.iam_email
}

# source repo role to allow read access to the CI/CD SA

resource "google_sourcerepo_repository_iam_member" "networking_reader" {
  for_each = {
    for k, v in google_sourcerepo_repository.networking : k => v.name
  }
  project    = var.automation.project_id
  repository = each.value
  role       = "roles/source.reader"
  member     = module.branch-network-sa-cicd.0.iam_email
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "branch-network-sa-cicd" {
  source = "../../../modules/iam-service-account"
  for_each = (
    lookup(local.cicd_repositories, "networking", null) == null
    ? {}
    : { 0 = local.cicd_repositories.networking }
  )
  project_id  = var.automation.project_id
  name        = "prod-resman-net-1"
  description = "Terraform CI/CD stage 2 networking service account."
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

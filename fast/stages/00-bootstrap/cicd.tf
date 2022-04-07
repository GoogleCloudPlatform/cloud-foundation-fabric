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
  _cicd_config = coalesce(var.cicd_config, {
    providers    = null
    repositories = null
  })
  cicd_providers = distinct(concat(
    [
      for k in coalesce(local._cicd_config.providers, []) : k
    ],
    [
      for k, v in coalesce(local._cicd_config.repositories, {}) :
      v.provider if v != null
    ]
  ))
  cicd_repositories = {
    for k, v in coalesce(local._cicd_config.repositories, {}) :
    k => v if v != null
  }
  cicd_service_accounts = {
    for k, v in module.automation-tf-cicd-sa : k => v.iam_email
  }
  cicd_tpl_principal = {
    GITHUB = "principal://iam.googleapis.com/%s/subject/repo:%s:ref:refs/heads/%s"
    GITLAB = "principal://iam.googleapis.com/%s/subject/project_path:%s:ref_type:branch:ref:%s"
  }
  cicd_tpl_principalset = (
    "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
  )
}

# TODO: check in resman for the relevant org policy
#       constraints/iam.workloadIdentityPoolProviders
# TODO: include pipeline configuration files in output files

resource "google_iam_workload_identity_pool" "default" {
  provider                  = google-beta
  count                     = length(local.cicd_providers) > 0 ? 1 : 0
  project                   = module.automation-project.project_id
  workload_identity_pool_id = "${var.prefix}-default"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider = google-beta
  count    = contains(local.cicd_providers, "GITHUB") ? 1 : 0
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.0.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-default-github"
  # TODO: limit via attribute_condition?
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.sub"        = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  provider = google-beta
  count    = contains(local.cicd_providers, "GITLAB") ? 1 : 0
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.0.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-default-gitlab"
  # TODO: limit via attribute_condition?
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.sub"        = "assertion.sub"
    "attribute.repository" = "assertion.project_path"
    "attribute.ref"        = "assertion.ref"
  }
  oidc {
    allowed_audiences = ["https://gitlab.com"]
    issuer_uri        = "https://gitlab.com"
  }
}

module "automation-tf-cicd-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.cicd_repositories
  project_id  = module.automation-project.project_id
  name        = "${each.key}-1"
  description = "Terraform CI/CD stage 1 ${each.key} service account."
  prefix      = local.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.cicd_tpl_principalset,
        google_iam_workload_identity_pool.default.0.name,
        each.value.name
      )
      : format(
        local.cicd_tpl_principal[each.value.provider],
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

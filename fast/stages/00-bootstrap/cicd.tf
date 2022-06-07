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

# tfdoc:file:description Workload Identity Federation configurations for CI/CD.

locals {
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null
      &&
      (
        v.type == "sourcerepo"
        ||
        contains(keys(local.identity_providers), coalesce(v.identity_provider, ":"))
      )
      &&
      fileexists("${path.module}/templates/workflow-${v.type}.yaml")
    )
  }
  cicd_workflow_var_files = {
    bootstrap = []
    resman = [
      "00-bootstrap.auto.tfvars.json",
      "globals.auto.tfvars.json"
    ]
  }
  cicd_workflow_providers = {
    bootstrap = "00-bootstrap-providers.tf"
    resman    = "01-resman-providers.tf"
  }
}

# source repositories

resource "google_sourcerepo_repository" "default" {
  for_each = {
    for k, v in local.cicd_repositories : k => v if v.type == "sourcerepo"
  }
  project = module.automation-project.project_id
  name    = each.value.name
}

resource "google_cloudbuild_trigger" "bootstrap" {
  for_each = {
    for k, v in google_sourcerepo_repository.default : k => v.name
    if k == "bootstrap"
  }
  project        = module.automation-project.project_id
  name           = "fast-00-bootstrap"
  included_files = ["**/*tf", ".cloudbuild/workflow.yaml"]
  trigger_template {
    project_id  = module.automation-project.project_id
    branch_name = local.cicd_repositories["bootstrap"].branch
    repo_name   = each.value
  }
  service_account = module.automation-tf-cicd-sa[each.key].id
  filename        = ".cloudbuild/workflow.yaml"
}

resource "google_sourcerepo_repository_iam_member" "admin" {
  for_each = {
    for k, v in google_sourcerepo_repository.default : k => v.name
  }
  project    = module.automation-project.project_id
  repository = each.value
  role       = "roles/source.admin"
  member = (
    each.key == "bootstrap"
    ? module.automation-tf-bootstrap-sa.iam_email
    : module.automation-tf-resman-sa.iam_email
  )
}

resource "google_sourcerepo_repository_iam_member" "reader" {
  for_each = {
    for k, v in google_sourcerepo_repository.default : k => v.name
  }
  project    = module.automation-project.project_id
  repository = each.value
  role       = "roles/source.reader"
  member     = module.automation-tf-cicd-sa[each.key].iam_email
}

# SAs used via workload identity federation to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source      = "../../../modules/iam-service-account"
  for_each    = local.cicd_repositories
  project_id  = module.automation-project.project_id
  name        = "${each.key}-1"
  description = "Terraform CI/CD ${each.key} service account."
  prefix      = local.prefix
  iam = (
    each.value.type == "sourcerepo"
    ? {}
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.branch == null
        ? format(
          local.identity_providers_defs[each.value.type].principalset_tpl,
          google_iam_workload_identity_pool.default.0.name,
          each.value.name
        )
        : format(
          local.identity_providers_defs[each.value.type].principal_tpl,
          google_iam_workload_identity_pool.default.0.name,
          each.value.name,
          each.value.branch
        )
      ]
    }
  )
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

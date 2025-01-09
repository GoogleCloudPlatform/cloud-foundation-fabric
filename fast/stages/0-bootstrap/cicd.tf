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

# tfdoc:file:description CI/CD locals and resources.

locals {
  _cicd_configs = merge(
    # stages
    {
      for k, v in var.cicd_config : k => merge(v, {
        level = k == "bootstrap" ? 0 : 1
        stage = k
      }) if v != null
    },
    # addons
    {
      for k, v in var.fast_addon : k => merge(v.cicd_config, {
        level = 1
        stage = substr(v.parent_stage, 2, -1)
      }) if v.cicd_config != null
    }
  )
  cicd_providers = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    k => {
      audiences = concat(
        v.oidc[0].allowed_audiences,
        ["https://iam.googleapis.com/${v.name}"]
      )
      issuer           = local.workload_identity_providers[k].issuer
      issuer_uri       = try(v.oidc[0].issuer_uri, null)
      name             = v.name
      principal_branch = local.workload_identity_providers[k].principal_branch
      principal_repo   = local.workload_identity_providers[k].principal_repo
    }
  }
  cicd_repositories = {
    for k, v in local._cicd_configs : k => v if(
      contains(keys(local.workload_identity_providers), v.identity_provider) &&
      fileexists("${path.module}/templates/workflow-${v.repository.type}.yaml")
    )
  }
  cicd_workflow_providers = merge(
    {
      for k, v in local.cicd_repositories :
      k => "${v.level}-${k}-providers.tf"
    },
    {
      for k, v in local.cicd_repositories :
      "${k}-r" => "${v.level}-${k}-r-providers.tf"
    }
  )
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.cicd_repositories
  project_id = module.automation-project.project_id
  name = templatestring(
    var.resource_names["sa-cicd_template"], { key = each.key }
  )
  display_name = "Terraform CI/CD ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.repository.branch == null
      ? format(
        local.workload_identity_providers_defs[each.value.repository.type].principal_repo,
        google_iam_workload_identity_pool.default[0].name,
        each.value.repository.name
      )
      : format(
        local.workload_identity_providers_defs[each.value.repository.type].principal_branch,
        google_iam_workload_identity_pool.default[0].name,
        each.value.repository.name,
        each.value.repository.branch
      )
    ]
  }
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

module "automation-tf-cicd-r-sa" {
  source     = "../../../modules/iam-service-account"
  for_each   = local.cicd_repositories
  project_id = module.automation-project.project_id
  name = templatestring(
    var.resource_names["sa-cicd_template_ro"], { key = each.key }
  )
  display_name = "Terraform CI/CD ${each.key} service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.workload_identity_providers_defs[each.value.repository.type].principal_repo,
        google_iam_workload_identity_pool.default[0].name,
        each.value.repository.name
      )
    ]
  }
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

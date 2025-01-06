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

# tfdoc:file:description Workload Identity Federation configurations for CI/CD.

locals {
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
  _cicd_configs = merge(
    # stages
    {
      for k, v in var.cicd_config : k => merge(v, {
        is_addon = false
        stage    = k
      }) if v != null
    },
    {
      for k, v in var.fast_addon : "${v.parent_stage}-${k}" => merge(v.cicd_config, {
        is_addon = true
        stage    = substr(v.parent_stage, 2, -1)
      }) if v.cicd_config != null
    }
  )
  cicd_repositories = {
    for k, v in local._cicd_configs : k => v if(
      contains(keys(local.workload_identity_providers), v.identity_provider) &&
      fileexists("${path.module}/templates/workflow-${v.repository.type}.yaml")
    )
  }
  cicd_workflow_providers = merge(
    {
      bootstrap   = "0-bootstrap-providers.tf"
      bootstrap_r = "0-bootstrap-r-providers.tf"
      resman      = "1-resman-providers.tf"
      resman_r    = "1-resman-r-providers.tf"
      vpcsc       = "1-vpcsc-providers.tf"
      vpcsc_r     = "1-vpcsc-r-providers.tf"
    },
    {
      for k, v in local.cicd_repositories :
      k => "${k}-providers.tf" if v.is_addon
    },
    {
      for k, v in local.cicd_repositories :
      "${k}_r" => "${k}-r-providers.tf" if v.is_addon
    },
  )
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.cicd_repositories : k => v if !v.is_addon
  }
  project_id = module.automation-project.project_id
  name = templatestring(
    var.resource_names["sa-cicd_template"], { key = each.key }
  )
  display_name = "Terraform CI/CD ${each.key} service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = concat(
      # this stage's repository
      [
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
      ],
      # this stage's addons repositories
      [
        for k, v in local.cicd_repositories : (
          v.repository.branch == null
          ? format(
            local.workload_identity_providers_defs[v.repository.type].principal_repo,
            google_iam_workload_identity_pool.default[0].name,
            v.name
          )
          : format(
            local.workload_identity_providers_defs[v.repository.type].principal_branch,
            google_iam_workload_identity_pool.default[0].name,
            v.repository.name,
            v.repository.branch
          )
        ) if v.is_addon && v.stage == each.key
      ]
    )
  }
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

module "automation-tf-cicd-r-sa" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.cicd_repositories : k => v if !v.is_addon
  }
  project_id = module.automation-project.project_id
  name = templatestring(
    var.resource_names["sa-cicd_template_ro"], { key = each.key }
  )
  display_name = "Terraform CI/CD ${each.key} service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = concat(
      # this stage's repository
      [
        format(
          local.workload_identity_providers_defs[each.value.repository.type].principal_repo,
          google_iam_workload_identity_pool.default[0].name,
          each.value.repository.name
        )
      ],
      # this stage's addons repositories
      [
        for k, v in local.cicd_repositories : format(
          local.workload_identity_providers_defs[v.repository.type].principal_repo,
          google_iam_workload_identity_pool.default[0].name,
          v.repository.name
        ) if v.is_addon && v.stage == each.key
      ]
    )
  }
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

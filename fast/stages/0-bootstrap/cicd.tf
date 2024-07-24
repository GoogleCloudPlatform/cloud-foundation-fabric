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
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null
      &&
      contains(
        keys(local.workload_identity_providers),
        coalesce(try(v.identity_provider, null), ":")
      )
      &&
      fileexists(
        format("${path.module}/templates/workflow-%s.yaml", try(v.type, ""))
      )
    )
  }
  cicd_workflow_providers = {
    bootstrap   = "0-bootstrap-providers.tf"
    bootstrap_r = "0-bootstrap-r-providers.tf"
    resman      = "1-resman-providers.tf"
    resman_r    = "1-resman-r-providers.tf"
    tenants     = "1-tenant-factory-providers.tf"
    tenants_r   = "1-tenant-factory-r-providers.tf"
    vpcsc       = "1-vpcsc-providers.tf"
    vpcsc_r     = "1-vpcsc-r-providers.tf"
  }
  cicd_workflow_var_files = {
    bootstrap = []
    resman = [
      "0-bootstrap.auto.tfvars.json",
      "0-globals.auto.tfvars.json"
    ]
    tenants = [
      "0-bootstrap.auto.tfvars.json",
      "0-globals.auto.tfvars.json"
    ]
    vpcsc = [
      "0-bootstrap.auto.tfvars.json",
      "0-globals.auto.tfvars.json"
    ]
  }
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.cicd_repositories
  project_id   = module.automation-project.project_id
  name         = "${each.key}-1"
  display_name = "Terraform CI/CD ${each.key} service account."
  prefix       = local.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.workload_identity_providers_defs[each.value.type].principal_repo,
        google_iam_workload_identity_pool.default[0].name,
        each.value.name
      )
      : format(
        local.workload_identity_providers_defs[each.value.type].principal_branch,
        google_iam_workload_identity_pool.default[0].name,
        each.value.name,
        each.value.branch
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
  source       = "../../../modules/iam-service-account"
  for_each     = local.cicd_repositories
  project_id   = module.automation-project.project_id
  name         = "${each.key}-1r"
  display_name = "Terraform CI/CD ${each.key} service account (read-only)."
  prefix       = local.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.workload_identity_providers_defs[each.value.type].principal_repo,
        google_iam_workload_identity_pool.default[0].name,
        each.value.name
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

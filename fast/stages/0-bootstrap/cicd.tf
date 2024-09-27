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
      (
        try(v.type, null) == "ssm"
        ||
        contains(
          keys(local.workload_identity_providers),
          coalesce(try(v.identity_provider, null), ":")
        )
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
  cicd_service_accounts = {
    bootstrap   = contains(keys(module.automation-tf-cicd-sa), "bootstrap") ? module.automation-tf-cicd-sa["bootstrap"].iam_email : ""
    bootstrap_r = contains(keys(module.automation-tf-cicd-r-sa), "bootstrap") ? module.automation-tf-cicd-r-sa["bootstrap"].iam_email : ""
    resman      = contains(keys(module.automation-tf-cicd-sa), "resman") ? module.automation-tf-cicd-sa["resman"].iam_email : ""
    resman_r    = contains(keys(module.automation-tf-cicd-r-sa), "resman") ? module.automation-tf-cicd-r-sa["resman"].iam_email : ""
    tenants     = contains(keys(module.automation-tf-cicd-sa), "tenants") ? module.automation-tf-cicd-sa["tenants"].iam_email : ""
    tenants_r   = contains(keys(module.automation-tf-cicd-r-sa), "tenants") ? module.automation-tf-cicd-r-sa["tenants"].iam_email : ""
    vpcsc       = contains(keys(module.automation-tf-cicd-sa), "vpcsc") ? module.automation-tf-cicd-sa["vpcsc"].iam_email : ""
    vpcsc_r     = contains(keys(module.automation-tf-cicd-r-sa), "vpcsc") ? module.automation-tf-cicd-r-sa["vpcsc"].iam_email : ""
  }
}

# Secure Source Manager instance and repositories

module "automation-tf-cicd-ssm" {
  source = "../../../modules/secure-source-manager-instance"
  count = (
    contains([for repo in values(coalesce(local.cicd_repositories, {})) : repo.type], "ssm")
  ) ? 1 : 0
  project_id  = module.automation-project.project_id
  location    = local.locations.ssm
  instance_id = "iac-core-ssm-0"
  iam = {
    "roles/securesourcemanager.instanceOwner" = compact([
      local.cicd_service_accounts["bootstrap"],
      local.cicd_service_accounts["resman"]
    ])
    "roles/securesourcemanager.instanceAccessor" = compact(distinct([
      local.cicd_service_accounts["bootstrap"],
      local.cicd_service_accounts["resman"],
      local.cicd_service_accounts["bootstrap_r"],
      local.cicd_service_accounts["resman_r"],
      local.cicd_service_accounts["tenants_r"],
      local.cicd_service_accounts["vpcsc_r"],
      var.bootstrap_user != null ? "user:${var.bootstrap_user}" : null
    ]))
  }
  repositories = {
    for repo_key, repo in local.cicd_repositories :
    coalesce(repo.name, repo_key) => {
      location = local.locations.ssm # tmp, to be removed after PR#2595
      iam = {
        "roles/securesourcemanager.repoAdmin" = compact(distinct([
          contains(keys(local.cicd_service_accounts), "bootstrap") ? local.cicd_service_accounts["bootstrap"] : null,
          contains(keys(local.cicd_service_accounts), repo_key) ? local.cicd_service_accounts[repo_key] : null,
          var.bootstrap_user != null ? "user:${var.bootstrap_user}" : null
        ]))
        "roles/securesourcemanager.repoReader" = compact(distinct([
          contains(keys(local.cicd_service_accounts), "bootstrap_r") ? local.cicd_service_accounts["bootstrap_r"] : null,
          contains(keys(local.cicd_service_accounts), "${repo_key}_r") ? local.cicd_service_accounts["${repo_key}_r"] : null
        ]))
      }
    }
    if repo.type == "ssm"
  }
}

# Push stages to the repos

resource "null_resource" "git_init" {
  for_each = { for k, v in local.cicd_repositories : k => v if v.type == "ssm" }

  provisioner "local-exec" {
    command = <<EOT
      bash ${path.module}/scripts/stages-to-get.sh ${
    each.key == "bootstrap" ? path.module : (
      each.key == "tenants" ? "${path.module}/../1-tenant-factory" : "${path.module}/../1-${each.key}"
    )
  } ${module.automation-tf-cicd-ssm.repositories[each.key].uris.git_https} ${each.value.branch}
    EOT
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
  iam = each.value.type != "ssm" ? {
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
  } : {}
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
  iam = each.value.type != "ssm" ? {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.workload_identity_providers_defs[each.value.type].principal_repo,
        google_iam_workload_identity_pool.default[0].name,
        each.value.name
      )
    ]
  } : {}
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

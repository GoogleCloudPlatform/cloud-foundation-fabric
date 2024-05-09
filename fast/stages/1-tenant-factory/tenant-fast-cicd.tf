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

# tfdoc:file:description Per-tenant CI/CD resources.

locals {
  # alias resources for readability
  _wif_providers = {
    for k, v in google_iam_workload_identity_pool_provider.default : k => v
  }
  _cicd_providers = [
    for k, v in local.workload_identity_providers : {
      audiences = concat(
        local._wif_providers[k].oidc[0].allowed_audiences,
        ["https://iam.googleapis.com/${local._wif_providers[k].name}"]
      )
      issuer           = v.issuer
      issuer_uri       = try(local._wif_providers[k].oidc[0].issuer_uri, null)
      name             = local._wif_providers[k].name
      principal_branch = v.principal_branch
      principal_repo   = v.principal_repo
      provider         = v.provider
      tenant           = v.tenant
    }
  ]
  _cicd_tenant_providers = {
    for v in local._cicd_providers : v.tenant => v...
  }
  cicd_tenant_providers = {
    for k, v in local._cicd_tenant_providers : k => {
      for pv in v : pv.provider => pv
    }
  }
  cicd_repositories = {
    for k, v in local.fast_tenants :
    k => merge(v.fast_config.cicd_config, {
      tenant = k
    })
    if(
      try(v.fast_config.cicd_config, null) != null &&
      (
        try(v.fast_config.cicd_config.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.identity_providers[k]),
          coalesce(try(v.fast_config.cicd_config.identity_provider, null), ":")
        )
      ) &&
      fileexists(
        "${path.module}/templates/workflow-${try(v.fast_config.cicd_config.type, "")}.yaml"
      )
    )
  }
  identity_providers = {
    for k, v in local.fast_tenants : k => merge(
      try(var.automation.federated_identity_providers, {}),
      try(local.cicd_tenant_providers[k], {})
    )
  }
}
output "foo" {
  value = local.identity_providers
}
module "tenant-cicd-repo" {
  source = "../../../modules/source-repository"
  for_each = {
    for k, v in local.cicd_repositories :
    k => v if v.type == "sourcerepo"
  }
  project_id = module.tenant-automation-project[each.key].project_id
  name       = "tenant-${each.key}-resman"
  iam = {
    "roles/source.admin" = [
      module.tenant-automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/source.reader" = [
      module.tenant-automation-tf-cicd-sa[each.key].iam_email
    ]
  }
  triggers = {
    fast-02-security = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.tenant-automation-tf-cicd-sa[each.key].id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.branch
        repo_name   = each.value.name
        tag_name    = null
      }
    }
  }
  depends_on = [module.tenant-automation-tf-cicd-sa]
}


# read-write (apply) SA used by CI/CD workflows to impersonate automation SA

module "tenant-automation-tf-cicd-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.cicd_repositories
  project_id   = var.automation.project_id
  name         = "${each.key}-1"
  display_name = "Terraform CI/CD ${each.key} service account."
  prefix       = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.branch == null
        ? format(
          local.identity_providers[each.value.tenant][each.value.identity_provider].principal_repo,
          var.automation.federated_identity_pool,
          each.value.name
        )
        : format(
          local.identity_providers[each.value.tenant][each.value.identity_provider].principal_branch,
          var.automation.federated_identity_pool,
          each.value.name,
          each.value.branch
        )
      ]
    }
  )
  iam_project_roles = {
    (module.tenant-automation-project[each.key].project_id) = [
      "roles/logging.logWriter"
    ]
  }
  iam_storage_roles = {
    (module.tenant-automation-tf-output-gcs[each.key].name) = [
      "roles/storage.objectViewer"
    ]
  }
}

# read-only (plan) SA used by CI/CD workflows to impersonate automation SA

module "automation-tf-cicd-r-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.cicd_repositories
  project_id   = var.automation.project_id
  name         = "tenant-${each.key}-1r"
  display_name = "Terraform CI/CD ${each.key} service account (read-only)."
  prefix       = var.prefix
  iam = (
    each.value.type == "sourcerepo"
    # build trigger for read-only SA is optionally defined by users
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        format(
          local.identity_providers[each.value.tenant][each.value.identity_provider].principal_repo,
          var.automation.federated_identity_pool,
          each.value.name
        )
      ]
    }
  )
  iam_project_roles = {
    (module.tenant-automation-project[each.key].project_id) = [
      "roles/logging.logWriter"
    ]
  }
  iam_storage_roles = {
    (module.tenant-automation-tf-output-gcs[each.key].name) = [
      "roles/storage.objectViewer"
    ]
  }
}

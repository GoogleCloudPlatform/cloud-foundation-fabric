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
  # aggregate provider data from configurations and resources
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
  # group provider data by tenant
  _cicd_tenant_providers = {
    for v in local._cicd_providers : v.tenant => v...
  }
  # reconstitue per-tenant provider lists as maps
  cicd_tenant_providers = {
    for k, v in local._cicd_tenant_providers : k => {
      for pv in v : pv.provider => pv
    }
  }
  # filter tenant provider definitions to only keep valid ones
  cicd_repositories = {
    for k, v in local.fast_tenants :
    k => merge(v.fast_config.cicd_config, {
      tenant = k
    })
    # only keep CI/CD configurations that
    if(
      # are not null
      try(v.fast_config.cicd_config, null) != null
      &&
      # are of a valid type (a template file exists for the type)
      fileexists(
        "${path.module}/templates/workflow-${try(v.fast_config.cicd_config.type, "")}.yaml"
      )
      &&
      # either
      (
        # use an org-level WIF provider, or
        try(var.automation.federated_identity_providers[v.wif_provider], null) != null
        ||
        # use a tenant-level WIF provider
        try(v.fast_config.workload_identity_providers[v.wif_provider], null) != null
      )
    )
  }
  # merge org-level and tenant-level providers for each tenant
  identity_providers = {
    for k, v in local.fast_tenants : k => merge(
      try(var.automation.federated_identity_providers, {}),
      try(local.cicd_tenant_providers[k], {})
    )
  }
}

# read-write (apply) SA used by CI/CD workflows to impersonate automation SA

module "tenant-automation-tf-cicd-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.cicd_repositories
  project_id   = var.automation.project_id
  name         = "${each.key}-1"
  display_name = "Terraform CI/CD ${each.key} service account."
  prefix       = var.prefix
  iam = {
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
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.tenant][each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
    ]
  }
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

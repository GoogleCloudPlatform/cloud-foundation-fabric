/**
 * Copyright 2023 Google LLC
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
  _file_prefix = "tenants/${var.tenant_config.short_name}"
  # derive identity pool names from identity providers for easy reference
  cicd_identity_pools = {
    for k, v in local.cicd_providers :
    k => split("/providers/", v.name)[0]
  }
  # merge org-level and tenant-level identity providers
  cicd_providers = merge(
    var.automation.federated_identity_providers,
    {
      for k, v in google_iam_workload_identity_pool_provider.default :
      k => {
        audiences = concat(
          v.oidc[0].allowed_audiences,
          ["https://iam.googleapis.com/${v.name}"]
        )
        issuer           = local.identity_providers[k].issuer
        issuer_uri       = try(v.oidc[0].issuer_uri, null)
        name             = v.name
        principal_tpl    = local.identity_providers[k].principal_tpl
        principalset_tpl = local.identity_providers[k].principalset_tpl
      }
    }
  )
  cicd_repositories = {
    for k, v in coalesce(var.cicd_repositories, {}) : k => v
    if(
      v != null
      &&
      (
        try(v.type, null) == "sourcerepo"
        ||
        contains(
          keys(local.cicd_providers),
          coalesce(try(v.identity_provider, null), ":")
        )
      )
      &&
      fileexists(
        format("${path.module}/templates/workflow-%s.yaml", try(v.type, ""))
      )
    )
  }
  cicd_sa_resman = try(
    module.automation-tf-cicd-sa-bootstrap["0"].iam_email, null
  )
}

# tenant bootstrap runs in the org scope and uses top-level automation project

module "automation-tf-cicd-repo-bootstrap" {
  source = "../../../modules/source-repository"
  for_each = {
    for k, v in local.cicd_repositories : 0 => v
    if k == "bootstrap" && try(v.type, null) == "sourcerepo"
  }
  project_id = var.automation.project_id
  name       = each.value.name
  iam = {
    "roles/source.admin" = [
      local.resman_sa
    ]
    "roles/source.reader" = [
      module.automation-tf-cicd-sa-bootstrap["0"].iam_email
    ]
  }
  triggers = {
    "fast-${var.tenant_config.short_name}-0-bootstrap" = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.automation-tf-cicd-sa-bootstrap["0"].id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.branch
        repo_name   = each.value.name
        tag_name    = null
      }
    }
  }
}

module "automation-tf-cicd-sa-bootstrap" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.cicd_repositories : 0 => v
    if k == "bootstrap" && try(v.type, null) != null
  }
  project_id   = var.automation.project_id
  name         = "bootstrap-1"
  display_name = "Terraform CI/CD ${var.tenant_config.short_name} bootstrap."
  prefix       = local.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.branch == null
        ? format(
          local.cicd_providers[each.value.identity_provider].principalset_tpl,
          local.cicd_identity_pools[each.value.identity_provider],
          each.value.name
        )
        : format(
          local.cicd_providers[each.value.identity_provider].principal_tpl,
          local.cicd_identity_pools[each.value.identity_provider],
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

module "automation-tf-org-resman-sa" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.cicd_repositories : 0 => v
    if k == "bootstrap" && try(v.type, null) != null
  }
  project_id             = var.automation.project_id
  name                   = local.resman_sa
  service_account_create = false
  iam_bindings_additive = local.cicd_sa_resman == null ? {} : {
    sa_resman_cicd = {
      member = local.cicd_sa_resman
      role   = "roles/iam.serviceAccountTokenCreator"
    }
  }
}

# tenant resman runs in the tenant scope and uses its own automation project

module "automation-tf-cicd-repo-resman" {
  source = "../../../modules/source-repository"
  for_each = {
    for k, v in local.cicd_repositories : 0 => v
    if k == "resman" && try(v.type, null) == "sourcerepo"
  }
  project_id = module.automation-project.project_id
  name       = each.value.name
  iam = {
    "roles/source.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/source.reader" = [
      module.automation-tf-cicd-sa-resman["0"].iam_email
    ]
  }
  triggers = {
    fast-1-resman = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.automation-tf-cicd-sa-resman["0"].id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.branch
        repo_name   = each.value.name
        tag_name    = null
      }
    }
  }
}

module "automation-tf-cicd-sa-resman" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in local.cicd_repositories : 0 => v
    if k == "resman" && try(v.type, null) != null
  }
  project_id   = module.automation-project.project_id
  name         = "resman-1"
  display_name = "Terraform CI/CD resman."
  prefix       = local.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.branch == null
        ? format(
          local.cicd_providers[each.value.identity_provider].principalset_tpl,
          local.cicd_identity_pools[each.value.identity_provider],
          each.value.name
        )
        : format(
          local.cicd_providers[each.value.identity_provider].principal_tpl,
          local.cicd_identity_pools[each.value.identity_provider],
          each.value.name,
          each.value.branch
        )
      ]
    }
  )
  iam_project_roles = {
    (module.automation-project.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs.name) = ["roles/storage.objectViewer"]
  }
}

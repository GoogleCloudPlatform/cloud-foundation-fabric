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
  cicd_repository_types = {
    for k, v in var.tenant_configs : k => try(v.cicd.type, null)
  }
  cicd_workflow_providers = {
    resman = "01-resman-providers.tf"
  }
  cicd_workflow_var_files = {
    resman = [
      "00-bootstrap.auto.tfvars.json",
      "globals.auto.tfvars.json"
    ]
  }
  identity_providers = coalesce(
    try(var.automation.federated_identity_providers, null), {}
  )
}

# source repository

module "automation-tf-cicd-repo" {
  source = "../../../modules/source-repository"
  for_each = {
    for k, v in var.tenant_configs :
    k => v if try(v.cicd.repository_type, null) == "sourcerepo"
  }
  project_id = module.automation-project[each.key].project_id
  name       = "resman"
  iam = {
    "roles/source.admin" = [
      module.automation-tf-resman-sa[each.key].iam_email
    ]
    "roles/source.reader" = [
      module.automation-tf-cicd-sa[each.key].iam_email
    ]
  }
  triggers = {
    fast-1-0-resman = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.automation-tf-cicd-sa[each.key].id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = each.value.cicd.branch
        repo_name   = each.value.cicd.name
        tag_name    = null
      }
    }
  }
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source = "../../../modules/iam-service-account"
  for_each = {
    for k, v in var.tenant_configs : k => v if v.cicd != null
  }
  project_id   = module.automation-project[each.key].project_id
  name         = "iac-core-resman-0c"
  display_name = "Terraform CI/CD tenant bootstrap service account."
  prefix       = local.prefixes[each.key]
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        each.value.cicd.branch == null
        ? format(
          local.identity_providers[each.value.cicd.repository_type].principalset_tpl,
          var.automation.federated_identity_pool,
          each.value.cicd.name
        )
        : format(
          local.identity_providers[each.value.cicd.repository_type].principal_tpl,
          var.automation.federated_identity_pool,
          each.value.cicd.name,
          each.value.cicd.branch
        )
      ]
    }
  )
  iam_project_roles = {
    (module.automation-project[each.key].project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (module.automation-tf-output-gcs[each.key].name) = ["roles/storage.objectViewer"]
  }
}

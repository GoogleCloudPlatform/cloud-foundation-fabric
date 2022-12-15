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
  cicd_repository_type = try(var.tenant_config.cicd.type, null)
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
  source     = "../../../modules/source-repository"
  count      = local.cicd_repository_type == "sourcerepo" ? 1 : 0
  project_id = module.automation-project.project_id
  name       = "resman"
  iam = {
    "roles/source.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/source.reader" = [
      module.automation-tf-cicd-sa.0.iam_email
    ]
  }
  triggers = {
    fast-1-0-resman = {
      filename        = ".cloudbuild/workflow.yaml"
      included_files  = ["**/*tf", ".cloudbuild/workflow.yaml"]
      service_account = module.automation-tf-cicd-sa.0.id
      substitutions   = {}
      template = {
        project_id  = null
        branch_name = var.tenant_config.cicd.branch
        repo_name   = var.tenant_config.cicd.name
        tag_name    = null
      }
    }
  }
}

# SAs used by CI/CD workflows to impersonate automation SAs

module "automation-tf-cicd-sa" {
  source       = "../../../modules/iam-service-account"
  count        = local.cicd_repository_type != null ? 1 : 0
  project_id   = module.automation-project.project_id
  name         = "iac-core-resman-0c"
  display_name = "Terraform CI/CD tenant bootstrap service account."
  prefix       = local.prefix
  iam = (
    each.value.type == "sourcerepo"
    # used directly from the cloud build trigger for source repos
    ? {}
    # impersonated via workload identity federation for external repos
    : {
      "roles/iam.workloadIdentityUser" = [
        var.tenant_config.cicd.branch == null
        ? format(
          local.identity_providers[local.cicd_repository_type].principalset_tpl,
          var.automation.federated_identity_pool,
          var.tenant_config.cicd.name
        )
        : format(
          local.identity_providers[local.cicd_repository_type].principal_tpl,
          var.automation.federated_identity_pool,
          var.tenant_config.cicd.name,
          var.tenant_config.cicd.branch
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

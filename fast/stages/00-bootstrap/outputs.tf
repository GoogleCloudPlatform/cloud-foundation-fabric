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

locals {
  custom_roles = {
    for k, v in var.custom_role_names :
    k => module.organization.custom_role_id[v]
  }
  providers = {
    "00-bootstrap" = templatefile("${path.module}/providers.tpl", {
      bucket = module.automation-tf-bootstrap-gcs.name
      name   = "bootstrap"
      sa     = module.automation-tf-bootstrap-sa.email
    })
    "01-resman" = templatefile("${path.module}/providers.tpl", {
      bucket = module.automation-tf-resman-gcs.name
      name   = "resman"
      sa     = module.automation-tf-resman-sa.email
    })
  }
  tfvars = {
    automation = {
      outputs_bucket = module.automation-tf-output-gcs.name
      project_id     = module.automation-project.project_id
    }
    cicd = {
      pool = try(google_iam_workload_identity_pool.default.0.name, null)
      providers = {
        github = try(google_iam_workload_identity_pool_provider.github.0.name, null)
        gitlab = try(google_iam_workload_identity_pool_provider.gitlab.0.name, null)
      }
      # TODO: this cannot be here or each stage will need to override it
      #       use this data to create dedicated workflow output files per stage
      service_accounts = local.cicd_service_accounts
    }
    custom_roles = local.custom_roles
  }
  tfvars_globals = {
    billing_account = var.billing_account
    groups          = var.groups
    organization    = var.organization
    prefix          = var.prefix
  }
}

# output files bucket

module "automation-tf-output-gcs" {
  source     = "../../../modules/gcs"
  project_id = module.automation-project.project_id
  name       = "iac-core-outputs-0"
  prefix     = local.prefix
  versioning = true
  depends_on = [module.organization]
}

resource "google_storage_bucket_object" "providers" {
  for_each = local.providers
  bucket   = module.automation-tf-output-gcs.name
  name     = "providers/${each.key}-providers.tf"
  content  = each.value
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = module.automation-tf-output-gcs.name
  name    = "tfvars/00-bootstrap.auto.tfvars.json"
  content = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars_globals" {
  bucket  = module.automation-tf-output-gcs.name
  name    = "tfvars/globals.tfvars.json"
  content = jsonencode(local.tfvars_globals)
}

# optionally generate providers and tfvars files for subsequent stages

resource "local_file" "providers" {
  for_each        = var.outputs_location == null ? {} : local.providers
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/providers/${each.key}-providers.tf"
  content         = each.value
}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/00-bootstrap.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "local_file" "tfvars_globals" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/globals.tfvars.json"
  content         = jsonencode(local.tfvars_globals)
}

# outputs

output "automation" {
  description = "Automation resources."
  value       = local.tfvars.automation
}

output "billing_dataset" {
  description = "BigQuery dataset prepared for billing export."
  value       = try(module.billing-export-dataset.0.id, null)
}

output "cicd_repositories" {
  description = "WIF configuration for CI/CD repositories."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch = v.branch
      name   = v.name
      provider = (
        v.provider == "GITHUB"
        ? google_iam_workload_identity_pool_provider.github.0.name
        : (
          v.provider == "GITLAB"
          ? google_iam_workload_identity_pool_provider.gitlab.0.name
          : null
        )
      )
      service_account = module.automation-tf-cicd-sa[k].email
    }
  }
}

output "custom_roles" {
  description = "Organization-level custom roles."
  value       = local.custom_roles
}

output "outputs_bucket" {
  description = "GCS bucket where generated output files are stored."
  value       = module.automation-tf-output-gcs.name
}

output "project_ids" {
  description = "Projects created by this stage."
  value = {
    automation     = module.automation-project.project_id
    billing-export = try(module.billing-export-project.0.project_id, null)
    log-export     = module.log-export-project.project_id
  }
}

output "service_accounts" {
  description = "Automation service accounts created by this stage."
  value = {
    bootstrap = module.automation-tf-bootstrap-sa.email
    resman    = module.automation-tf-resman-sa.email
  }
}

# ready to use provider configurations for subsequent stages when not using files

output "providers" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

# ready to use variable values for subsequent stages

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

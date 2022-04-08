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
  _tpl_providers = "${path.module}/templates/providers.tf"
  _workflow_attrs = {
    bootstrap = {
      service_account   = module.automation-tf-bootstrap-sa.email
      tf_providers_file = "00-bootstrap-providers.tf"
      tf_var_files      = []
    }
    resman = {
      service_account   = module.automation-tf-resman-sa.email
      tf_providers_file = "01-resman-providers.tf"
      tf_var_files = [
        "00-bootstrap.auto.tfvars.json",
        "globals.auto.tfvars.json"
      ]
    }
  }
  custom_roles = {
    for k, v in var.custom_role_names :
    k => module.organization.custom_role_id[v]
  }
  providers = {
    "00-bootstrap" = templatefile(local._tpl_providers, {
      bucket = module.automation-tf-bootstrap-gcs.name
      name   = "bootstrap"
      sa     = module.automation-tf-bootstrap-sa.email
    })
    "01-resman" = templatefile(local._tpl_providers, {
      bucket = module.automation-tf-resman-gcs.name
      name   = "resman"
      sa     = module.automation-tf-resman-sa.email
    })
  }
  tfvars = {
    automation = {
      outputs_bucket = module.automation-tf-output-gcs.name
      project_id     = module.automation-project.project_id
      wif_pool       = try(google_iam_workload_identity_pool.default.0.name, null)
      wif_providers  = local.wif_providers
    }
    custom_roles = local.custom_roles
  }
  # TODO: add cicd_config
  tfvars_globals = {
    billing_account = var.billing_account
    groups          = var.groups
    organization    = var.organization
    prefix          = var.prefix
  }
  wif_providers = {
    github = try(google_iam_workload_identity_pool_provider.github.0.name, null)
    gitlab = try(google_iam_workload_identity_pool_provider.gitlab.0.name, null)
  }
  workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.provider}.yaml",
      merge(local._workflow_attrs[k], {
        outputs_bucket = module.automation-tf-output-gcs.name
        stage_name     = k
        wif_provider   = local.wif_providers[v["provider"]]
      })
    )
  }
}

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
      branch          = v.branch
      name            = v.name
      provider        = local.wif_providers[v.provider]
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

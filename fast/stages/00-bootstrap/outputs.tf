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
  _cicd_workflow_attrs = {
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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml",
      merge(local._cicd_workflow_attrs[k], {
        identity_provider = local.wif_providers[v["identity_provider"]].name
        outputs_bucket    = module.automation-tf-output-gcs.name
        stage_name        = k
      })
    )
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
      federated_identity_pool = try(
        google_iam_workload_identity_pool.default.0.name, null
      )
      federated_identity_providers = local.wif_providers
      outputs_bucket               = module.automation-tf-output-gcs.name
      project_id                   = module.automation-project.project_id
    }
    custom_roles = local.custom_roles
  }
  tfvars_globals = {
    billing_account = var.billing_account
    groups          = var.groups
    organization    = var.organization
    prefix          = var.prefix
  }
  wif_providers = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    k => {
      issuer           = local.identity_providers[k].issuer
      issuer_uri       = local.identity_providers[k].issuer_uri
      name             = v.name
      principal_tpl    = local.identity_providers[k].principal_tpl
      principalset_tpl = local.identity_providers[k].principalset_tpl
    }
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
      provider        = local.wif_providers[v.identity_provider].name
      service_account = module.automation-tf-cicd-sa[k].email
    }
  }
}

output "custom_roles" {
  description = "Organization-level custom roles."
  value       = local.custom_roles
}

output "federated_identity" {
  description = "Workload Identity Federation pool and providers."
  value = {
    pool = try(
      google_iam_workload_identity_pool.default.0.name, null
    )
    providers = local.wif_providers
  }
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

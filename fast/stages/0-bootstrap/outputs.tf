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

locals {
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  # render CI/CD workflow templates
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml", {
        # If users give a list of custom audiences we set by default the first element.
        # If no audiences are given, we set https://iam.googleapis.com/{PROVIDER_NAME}
        audiences = try(
          local.cicd_providers[v["identity_provider"]].audiences, ""
        )
        identity_provider = try(
          local.cicd_providers[v["identity_provider"]].name, ""
        )
        outputs_bucket = module.automation-tf-output-gcs.name
        service_account = try(
          module.automation-tf-cicd-sa[k].email, ""
        )
        stage_name        = k
        tf_providers_file = local.cicd_workflow_providers[k]
        tf_var_files      = local.cicd_workflow_var_files[k]
      }
    )
  }
  custom_roles = merge(
    {
      for k, v in var.custom_role_names :
      k => try(module.organization.custom_role_id[v], "")
    },
    {
      for k, v in var.custom_roles :
      k => try(module.organization.custom_role_id[k], "")
    }
  )
  providers = {
    "0-bootstrap" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-bootstrap-gcs.name
      name          = "bootstrap"
      sa            = module.automation-tf-bootstrap-sa.email
    })
    "1-resman" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-resman-gcs.name
      name          = "resman"
      sa            = module.automation-tf-resman-sa.email
    })
    "0-bootstrap-tenant" = templatefile(local._tpl_providers, {
      backend_extra = join("\n", [
        "# remove the newline between quotes and set the tenant name as prefix",
        "prefix = \"",
        "\""
      ])
      bucket = module.automation-tf-resman-gcs.name
      name   = "bootstrap-tenant"
      sa     = module.automation-tf-resman-sa.email
    })
  }
  tfvars = {
    automation = {
      federated_identity_pool = try(
        google_iam_workload_identity_pool.default.0.name, null
      )
      federated_identity_providers = local.cicd_providers
      outputs_bucket               = module.automation-tf-output-gcs.name
      project_id                   = module.automation-project.project_id
      project_number               = module.automation-project.number
    }
    custom_roles = local.custom_roles
    logging = {
      project_id        = module.log-export-project.project_id
      project_number    = module.log-export-project.number
      writer_identities = module.organization.sink_writer_identities
    }
    org_policy_tags = {
      key_id = (
        module.organization.tag_keys[var.org_policies_config.tag_name].id
      )
      key_name = var.org_policies_config.tag_name
      values = {
        for k, v in module.organization.tag_values :
        split("/", k)[1] => v.id
      }
    }
  }
  tfvars_globals = {
    billing_account = var.billing_account
    fast_features   = var.fast_features
    groups          = var.groups
    locations       = var.locations
    organization    = var.organization
    prefix          = var.prefix
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
  description = "CI/CD repository configurations."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch          = v.branch
      name            = v.name
      provider        = try(local.cicd_providers[v.identity_provider].name, null)
      service_account = try(module.automation-tf-cicd-sa[k].email, null)
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
    providers = local.cicd_providers
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

# ready to use provider configurations for subsequent stages when not using files
output "providers" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

output "service_accounts" {
  description = "Automation service accounts created by this stage."
  value = {
    bootstrap = module.automation-tf-bootstrap-sa.email
    resman    = module.automation-tf-resman-sa.email
  }
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

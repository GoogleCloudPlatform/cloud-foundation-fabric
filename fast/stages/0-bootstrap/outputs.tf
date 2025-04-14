/**
 * Copyright 2025 Google LLC
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
    for k, v in local.cicd_repositories : "${v.level}-${k}" => templatefile(
      "${path.module}/templates/workflow-${v.repository.type}.yaml", {
        # If users give a list of custom audiences we set by default the first element.
        # If no audiences are given, we set https://iam.googleapis.com/{PROVIDER_NAME}
        audiences = try(
          local.cicd_providers[v.identity_provider].audiences, []
        )
        identity_provider = try(
          local.cicd_providers[v.identity_provider].name, ""
        )
        outputs_bucket = module.automation-tf-output-gcs.name
        service_accounts = {
          apply = try(module.automation-tf-cicd-sa[k].email, "")
          plan  = try(module.automation-tf-cicd-r-sa[k].email, "")
        }
        stage_name = k
        tf_providers_files = {
          apply = local.cicd_workflow_providers[k]
          plan  = local.cicd_workflow_providers["${k}-r"]
        }
        tf_var_files = k == "bootstrap" ? [] : [
          "0-bootstrap.auto.tfvars.json",
          "0-globals.auto.tfvars.json"
        ]
      }
    )
  }
  tfvars = {
    automation = {
      federated_identity_pool = try(
        google_iam_workload_identity_pool.default[0].name, null
      )
      federated_identity_providers = local.cicd_providers
      outputs_bucket               = module.automation-tf-output-gcs.name
      project_id                   = module.automation-project.project_id
      project_number               = module.automation-project.number
      service_accounts = {
        bootstrap   = module.automation-tf-bootstrap-sa.email
        bootstrap-r = module.automation-tf-bootstrap-r-sa.email
        resman      = module.automation-tf-resman-sa.email
        resman-r    = module.automation-tf-resman-r-sa.email
        vpcsc       = module.automation-tf-vpcsc-sa.email
        vpcsc-r     = module.automation-tf-vpcsc-r-sa.email
      }
    }
    billing = {
      dataset        = try(module.billing-export-dataset[0].id, null)
      project_id     = try(module.billing-export-project[0].project_id, null)
      project_number = try(module.billing-export-project[0].number, null)
    }
    custom_roles = module.organization.custom_role_id
    logging = {
      project_id        = module.log-export-project.project_id
      project_number    = module.log-export-project.number
      writer_identities = module.organization.sink_writer_identities
      destinations = {
        bigquery = try(module.log-export-dataset[0].id, null)
        logging  = { for k, v in module.log-export-logbucket : k => v.id }
        pubsub   = { for k, v in module.log-export-pubsub : k => v.id }
        storage  = try(module.log-export-gcs[0].id, null)
      }
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
    universe = var.universe
  }
  tfvars_globals = {
    billing_account = var.billing_account
    groups          = local.principals
    environments = {
      for k, v in var.environments : k => {
        is_default = v.is_default
        key        = k
        name       = v.name
        short_name = v.short_name != null ? v.short_name : k
        tag_name   = v.tag_name != null ? v.tag_name : lower(v.name)
      }
    }
    locations    = local.locations
    organization = var.organization
    prefix       = var.prefix
  }
}

output "automation" {
  description = "Automation resources."
  value       = local.tfvars.automation
}

output "billing_dataset" {
  description = "BigQuery dataset prepared for billing export."
  value       = try(module.billing-export-dataset[0].id, null)
}

output "cicd_repositories" {
  description = "CI/CD repository configurations."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch          = v.repository.branch
      name            = v.repository.name
      provider        = try(local.cicd_providers[v.identity_provider].name, null)
      service_account = try(module.automation-tf-cicd-sa[k].email, null)
    }
  }
}

output "custom_roles" {
  description = "Organization-level custom roles."
  value       = module.organization.custom_role_id
}

output "outputs_bucket" {
  description = "GCS bucket where generated output files are stored."
  value       = module.automation-tf-output-gcs.name
}

output "project_ids" {
  description = "Projects created by this stage."
  value = {
    automation     = module.automation-project.project_id
    billing-export = try(module.billing-export-project[0].project_id, null)
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

output "tfvars_globals" {
  description = "Terraform Globals variable files for the following stages."
  sensitive   = true
  value       = local.tfvars_globals
}

output "workforce_identity_pool" {
  description = "Workforce Identity Federation pool."
  value = {
    pool = try(
      google_iam_workforce_pool.default[0].name, null
    )
  }
}

output "workload_identity_pool" {
  description = "Workload Identity Federation pool and providers."
  value = {
    pool = try(
      google_iam_workload_identity_pool.default[0].name, null
    )
    providers = local.cicd_providers
  }
}

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
        service_accounts = {
          apply = try(module.automation-tf-cicd-sa[k].email, "")
          plan  = try(module.automation-tf-cicd-r-sa[k].email, "")
        }
        stage_name = k
        tf_providers_files = {
          apply = local.cicd_workflow_providers[k]
          plan  = local.cicd_workflow_providers["${k}_r"]
        }
        tf_var_files = local.cicd_workflow_var_files[k]
      }
    )
  }
  providers = {
    "0-bootstrap" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-bootstrap-gcs.name
      name          = "bootstrap"
      sa            = module.automation-tf-bootstrap-sa.email
    })
    "0-bootstrap-r" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-bootstrap-gcs.name
      name          = "bootstrap"
      sa            = module.automation-tf-bootstrap-r-sa.email
    })
    "1-resman" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-resman-gcs.name
      name          = "resman"
      sa            = module.automation-tf-resman-sa.email
    })
    "1-resman-r" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-resman-gcs.name
      name          = "resman"
      sa            = module.automation-tf-resman-r-sa.email
    })
    "1-tenant-factory" = templatefile(local._tpl_providers, {
      backend_extra = "prefix = \"tenant-factory\""
      bucket        = module.automation-tf-resman-gcs.name
      name          = "tenant-factory"
      sa            = module.automation-tf-resman-sa.email
    })
    "1-tenant-factory-r" = templatefile(local._tpl_providers, {
      backend_extra = "prefix = \"tenant-factory\""
      bucket        = module.automation-tf-resman-gcs.name
      name          = "tenant-factory"
      sa            = module.automation-tf-resman-r-sa.email
    })
    "1-vpcsc" = templatefile(local._tpl_providers, {
      backend_extra = "prefix = \"vpcsc\""
      bucket        = module.automation-tf-vpcsc-gcs.name
      name          = "vpcsc"
      sa            = module.automation-tf-vpcsc-sa.email
    })
    "1-vpcsc-r" = templatefile(local._tpl_providers, {
      backend_extra = "prefix = \"vpcsc\""
      bucket        = module.automation-tf-vpcsc-gcs.name
      name          = "vpcsc"
      sa            = module.automation-tf-vpcsc-r-sa.email
    })
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
  }
  tfvars_globals = {
    billing_account = var.billing_account
    groups          = local.principals
    environments    = var.environments
    locations       = local.locations
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
  value       = try(module.billing-export-dataset[0].id, null)
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

# output "test" {
#   value = {
#     checklist               = local.checklist
#     iam_roles_authoritative = local.iam_roles_authoritative
#     iam_roles_additive      = local.iam_roles_additive
#     test                    = local.checklist
#   }
# }

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
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

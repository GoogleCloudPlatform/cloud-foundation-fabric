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
  cicd_workflow_attrs = {
    project_factory_dev = {
      service_account   = try(module.branch-pf-dev-sa-cicd.0.email, null)
      tf_providers_file = "3-project-factory-dev-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
    project_factory_prod = {
      service_account   = try(module.branch-pf-prod-sa-cicd.0.email, null)
      tf_providers_file = "3-project-factory-prod-providers.tf"
      tf_var_files      = local.cicd_workflow_var_files.stage_3
    }
  }
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml",
      merge(local.cicd_workflow_attrs[k], {
        audiences = try(
          local.identity_providers[v.identity_provider].audiences, null
        )
        identity_provider = try(
          local.identity_providers[v.identity_provider].name, null
        )
        outputs_bucket = var.automation.outputs_bucket
        stage_name     = k
      })
    )
  }
  folder_ids = merge(
    {
      sandbox = try(module.branch-sandbox-folder.0.id, null)
    },
  )
  providers = merge(
    !var.fast_features.project_factory ? {} : {
      "3-project-factory-dev" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-dev-gcs.0.name
        name          = "team-dev"
        sa            = module.branch-pf-dev-sa.0.email
      })
      "3-project-factory-prod" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-pf-prod-gcs.0.name
        name          = "team-prod"
        sa            = module.branch-pf-prod-sa.0.email
      })
    },
    !var.fast_features.sandbox ? {} : {
      "9-sandbox" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-sandbox-gcs.0.name
        name          = "sandbox"
        sa            = module.branch-sandbox-sa.0.email
      })
    },
  )
  service_accounts = {
    project-factory-dev  = try(module.branch-pf-dev-sa.0.email, null)
    project-factory-prod = try(module.branch-pf-prod-sa.0.email, null)
    sandbox              = try(module.branch-sandbox-sa.0.email, null)
  }
  tfvars = {
    folder_ids       = local.folder_ids
    service_accounts = local.service_accounts
    tag_keys         = { for k, v in try(module.organization.tag_keys, {}) : k => v.id }
    tag_names        = var.tag_names
    tag_values       = { for k, v in try(module.organization.tag_values, {}) : k => v.id }
  }
}

output "cicd_repositories" {
  description = "WIF configuration for CI/CD repositories."
  value = {
    for k, v in local.cicd_repositories : k => {
      branch = v.branch
      name   = v.name
      provider = try(
        local.identity_providers[v.identity_provider].name, null
      )
      service_account = local.cicd_workflow_attrs[k].service_account
    } if v != null
  }
}

output "project_factories" {
  description = "Data for the project factories stage."
  value = !var.fast_features.project_factory ? {} : {
    dev = {
      bucket = module.branch-pf-dev-gcs.0.name
      sa     = module.branch-pf-dev-sa.0.email
    }
    prod = {
      bucket = module.branch-pf-prod-gcs.0.name
      sa     = module.branch-pf-prod-sa.0.email
    }
  }
}

# ready to use provider configurations for subsequent stages
output "providers" {
  # tfdoc:output:consumers 02-networking 02-security 03-dataplatform xx-sandbox xx-teams
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

output "sandbox" {
  # tfdoc:output:consumers xx-sandbox
  description = "Data for the sandbox stage."
  value = (
    var.fast_features.sandbox
    ? {
      folder          = module.branch-sandbox-folder.0.id
      gcs_bucket      = module.branch-sandbox-gcs.0.name
      service_account = module.branch-sandbox-sa.0.email
    }
    : null
  )
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

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
  provider = templatefile(
    "${path.module}/templates/providers.tf.tpl", {
      bucket = module.automation-tf-resman-gcs.name
      name   = "resman"
      sa     = module.automation-tf-resman-sa.email
    }
  )
  tfvars = {
    automation = {
      outputs_bucket               = module.automation-tf-output-gcs.name
      project_id                   = module.automation-project.project_id
      project_number               = module.automation-project.number
      federated_identity_pool      = var.automation.federated_identity_pool
      federated_identity_providers = var.automation.federated_identity_providers
    }
    billing_account = var.billing_account
    custom_roles    = var.custom_roles
    fast_features   = var.fast_features
    groups          = var.tenant_config.groups
    locations       = local.locations
    organization    = var.organization
    prefix          = local.prefix
    root_node       = module.tenant-folder.id
    service_accounts = merge(
      { resman = module.automation-tf-resman-sa.email },
      {
        for k, v in local.branch_sas : k => try(
          module.automation-tf-resman-sa-stage2-3[k].email, null
        )
      }
    )
    tag_keys  = var.tag_keys
    tag_names = var.tag_names
    tag_values = merge(var.tag_values, {
      for k, v in module.organization.tag_values : k => v.id
    })
  }
  workflow = local.cicd_repository_type == null ? null : templatefile(
    "${path.module}/templates/workflow-${local.cicd_repository_type}.yaml", {
      identity_provider = try(
        local.identity_providers[var.tenant_config.cicd.identity_provider].name,
        ""
      )
      outputs_bucket    = module.automation-tf-output-gcs.name
      service_account   = try(module.automation-tf-cicd-sa.email, "")
      stage_name        = "resman"
      tf_providers_file = "01-resman-providers.tf"
      tf_var_files      = "00-bootstrap.auto.tfvars.json"
    }
  )
}

output "tenant_resources" {
  description = "Tenant-level resources."
  value = {
    bucket          = module.automation-tf-resman-gcs.name
    folder          = module.tenant-folder.id
    project_id      = module.automation-project.project_id
    project_number  = module.automation-project.number
    service_account = module.automation-tf-resman-sa.email
  }
}

output "provider" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider file for tenant resource management stage."
  sensitive   = true
  value       = local.provider
}

output "tfvars" {
  description = "Terraform variable files for the following tenant stages."
  sensitive   = true
  value       = local.tfvars
}

output "workflow" {
  description = "CI/CD workflow for tenant resource management stage."
  sensitive   = true
  value       = local.workflow
}

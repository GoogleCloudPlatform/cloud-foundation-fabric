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
  providers = {
    for k, v in var.tenant_configs : k => templatefile(
      "${path.module}/templates/providers.tf.tpl", {
        bucket = module.automation-tf-resman-gcs[k].name
        name   = "resman"
        sa     = module.automation-tf-resman-sa[k].email
      }
    )
  }
  tfvars = {
    for k, v in var.tenant_configs : k => {
      automation = {
        outputs_bucket               = module.automation-tf-output-gcs[k].name
        project_id                   = module.automation-project[k].project_id
        project_number               = module.automation-project[k].number
        federated_identity_pool      = var.automation.federated_identity_pool
        federated_identity_providers = var.automation.federated_identity_providers
      }
      billing_account = var.billing_account
      custom_roles    = var.custom_roles
      fast_features   = var.fast_features
      locations       = local.locations[k]
      organization    = var.organization
      prefix          = local.prefixes[k]
      root_node       = module.tenant-folder[k].id
    }
  }
  workflows = {
    for k, v in var.tenant_configs :
    k => try(v.cicd.repository_type, null) == null ? "" : templatefile(
      "${path.module}/templates/workflow-${v.cicd.repository_type}.yaml", {
        identity_provider = try(
          local.identity_providers[v.cicd.identity_provider].name, ""
        )
        outputs_bucket    = module.automation-tf-output-gcs[k].name
        service_account   = try(module.automation-tf-cicd-sa[k].email, "")
        stage_name        = "resman"
        tf_providers_file = "1-0-resman-providers.tf"
        tf_var_files      = "0-0-bootstrap.auto.tfvars.json"
      }
    )
  }
}

output "tenant_resources" {
  description = "Tenant-level resources."
  value = {
    for k, v in var.tenant_configs : k => {
      bucket          = module.automation-tf-resman-gcs[k].name
      folder          = module.tenant-folder[k].id
      project_id      = module.automation-project[k].project_id
      project_number  = module.automation-project[k].number
      service_account = module.automation-tf-resman-sa[k].email
    }
  }
}

output "providers" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider file for tenant resource management stage."
  sensitive   = true
  value       = local.providers
}

output "tfvars" {
  description = "Terraform variable files for the following tenant stages."
  sensitive   = true
  value       = local.tfvars
}

output "workflows" {
  description = "CI/CD workflow for tenant resource management stage."
  sensitive   = true
  value       = local.workflows
}

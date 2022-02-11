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
  _custom_roles = {
    for k, v in var.custom_role_names :
    k => module.organization.custom_role_id[v]
  }
  providers = {
    "00-bootstrap" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.automation-tf-bootstrap-gcs.name
      name   = "bootstrap"
      sa     = module.automation-tf-bootstrap-sa.email
    })
    "01-resman" = templatefile("${path.module}/../../assets/templates/providers.tpl", {
      bucket = module.automation-tf-resman-gcs.name
      name   = "resman"
      sa     = module.automation-tf-resman-sa.email
    })
  }
  tfvars = {
    "01-resman" = jsonencode({
      automation_project_id = module.automation-project.project_id
      billing_account       = var.billing_account
      custom_roles          = local._custom_roles
      groups                = var.groups
      organization          = var.organization
      prefix                = var.prefix
    })
    "02-networking" = jsonencode({
      billing_account_id = var.billing_account.id
      custom_roles       = local._custom_roles
      organization       = var.organization
      prefix             = var.prefix
    })
    "02-security" = jsonencode({
      billing_account_id = var.billing_account.id
      organization       = var.organization
      prefix             = var.prefix
    })
    "03-gke-multitenant-dev" = jsonencode({
      billing_account_id = var.billing_account.id
      prefix             = var.prefix
    })
    "03-gke-multitenant-prod" = jsonencode({
      billing_account_id = var.billing_account.id
      prefix             = var.prefix
    })
    "03-project-factory-dev" = jsonencode({
      billing_account_id = var.billing_account.id
      prefix             = var.prefix
    })
    "03-project-factory-prod" = jsonencode({
      billing_account_id = var.billing_account.id
      prefix             = var.prefix
    })
    "03-data-platform-dev" = jsonencode({
      billing_account_id  = var.billing_account.id
      organization_domain = var.organization.domain
      prefix              = var.prefix
    })
    "03-data-platform-prod" = jsonencode({
      billing_account_id  = var.billing_account.id
      organization_domain = var.organization.domain
      prefix              = var.prefix
    })
  }
}

# optionally generate providers and tfvars files for subsequent stages

resource "local_file" "providers" {
  for_each = var.outputs_location == null ? {} : local.providers
  filename = "${pathexpand(var.outputs_location)}/${each.key}/providers.tf"
  content  = each.value
}

resource "local_file" "tfvars" {
  for_each = var.outputs_location == null ? {} : local.tfvars
  filename = "${pathexpand(var.outputs_location)}/${each.key}/terraform-bootstrap.auto.tfvars.json"
  content  = each.value
}

# outputs

output "billing_dataset" {
  description = "BigQuery dataset prepared for billing export."
  value       = try(module.billing-export-dataset.0.id, null)
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

# ready to use variable values for subsequent stages

output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

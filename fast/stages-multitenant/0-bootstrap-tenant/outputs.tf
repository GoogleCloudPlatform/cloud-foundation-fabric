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
  cicd_workflows = {
    for k, v in local.cicd_repositories : k => templatefile(
      "${path.module}/templates/workflow-${v.type}.yaml", (
        k == "bootstrap"
        ? {
          audiences = local.cicd_providers[v["identity_provider"]].audiences
          identity_provider = try(
            local.cicd_providers[v["identity_provider"]].name, ""
          )
          outputs_bucket = var.automation.outputs_bucket
          service_account = try(
            module.automation-tf-cicd-sa-bootstrap["0"].email, ""
          )
          stage_name        = k
          tf_providers_file = ""
          tf_var_files = [
            "0-bootstrap.auto.tfvars.json",
            "1-resman.auto.tfvars.json",
            "0-globals.auto.tfvars.json"
          ]
        }
        : {
          audiences = local.cicd_providers[v["identity_provider"]].audiences
          identity_provider = try(
            local.cicd_providers[v["identity_provider"]].name, ""
          )
          outputs_bucket = module.automation-tf-output-gcs.name
          service_account = try(
            module.automation-tf-cicd-sa-resman["0"].email, ""
          )
          stage_name = k
          tf_providers_file = (
            "${local._file_prefix}/providers/1-resman-tenant-providers.tf"
          )
          tf_var_files = [
            "${local._file_prefix}/tfvars/0-bootstrap-tenant.auto.tfvars.json"
          ]
        }
      )
    )
  }
  provider = templatefile(
    "${path.module}/templates/providers.tf.tpl", {
      bucket = module.automation-tf-resman-gcs.name
      name   = "resman"
      sa     = module.automation-tf-resman-sa.email
    }
  )
  tfvars = {
    automation = {
      outputs_bucket = module.automation-tf-output-gcs.name
      project_id     = module.automation-project.project_id
      project_number = module.automation-project.number
      federated_identity_pools = compact([
        try(google_iam_workload_identity_pool.default.0.name, null),
        var.automation.federated_identity_pool,
      ])
      federated_identity_providers = local.cicd_providers
      service_accounts = merge(
        { resman = module.automation-tf-resman-sa.email },
        {
          for k, v in local.branch_sas : k => try(
            module.automation-tf-resman-sa-stage2-3[k].email, null
          )
        }
      )
    }
    billing_account = var.billing_account
    custom_roles    = var.custom_roles
    fast_features   = local.fast_features
    groups          = var.tenant_config.groups
    locations       = local.locations
    logging = {
      project_id        = module.log-export-project.project_id
      project_number    = module.log-export-project.number
      writer_identities = module.organization.sink_writer_identities
    }
    organization = var.organization
    prefix       = local.prefix
    root_node    = module.tenant-folder.id
    short_name   = var.tenant_config.short_name
    tags = {
      keys  = var.tag_keys
      names = var.tag_names
      values = merge(var.tag_values, {
        for k, v in module.organization.tag_values : k => v.id
      })
    }
  }
}

output "cicd_workflows" {
  description = "CI/CD workflows for tenant bootstrap and resource management stages."
  sensitive   = true
  value       = local.cicd_workflows
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

output "provider" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider file for tenant resource management stage."
  sensitive   = true
  value       = local.provider
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

output "tfvars" {
  description = "Terraform variable files for the following tenant stages."
  sensitive   = true
  value       = local.tfvars
}

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
  tenant_cicd_workflows = {
    for k, v in local.cicd_repositories :
    k => templatefile("${path.module}/templates/workflow-${v.type}.yaml", {
      audiences = try(
        local.identity_providers[v.tenant][v.identity_provider].audiences, null
      )
      identity_provider = try(
        local.identity_providers[v.tenant][v.identity_provider].name, null
      )
      outputs_bucket = try(
        module.tenant-automation-tf-output-gcs[k].name, null
      )
      service_accounts = {
        apply = try(module.tenant-automation-tf-resman-sa[k].email, null)
        plan  = try(module.tenant-automation-tf-resman-r-sa[k].email, null)
      }
      stage_name = "1-resman"
      tf_providers_files = {
        apply = "1-resman-providers.tf"
        plan  = "1-resman-r-providers.tf"
      }
      tf_var_files = [
        "0-bootstrap.auto.tfvars.json",
        "0-globals.auto.tfvars.json"
      ]
    })
  }
  tenant_data = {
    for k, v in local.tenants : k => {
      folder_id       = module.tenant-folder[k].id
      gcs_bucket      = module.tenant-gcs[k].id
      service_account = module.tenant-sa[k].email
      vpcsc_policy_id = try(module.tenant-vpcsc-policy[k].id, null)
    }
  }
  tenant_providers = {
    for k, v in local.fast_tenants : k => templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.tenant-automation-tf-resman-gcs[k].name
      name          = k
      sa            = module.tenant-automation-tf-resman-sa[k].email
    })
  }
  tenant_providers_r = {
    for k, v in local.fast_tenants : k => templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.tenant-automation-tf-resman-gcs[k].name
      name          = k
      sa            = module.tenant-automation-tf-resman-r-sa[k].email
    })
  }
  tenant_globals = {
    for k, v in local.fast_tenants : k => {
      billing_account = v.billing_account
      groups          = v.principals
      locations       = v.locations
      organization    = v.organization
      prefix          = v.prefix
    }
  }
  tenant_tfvars = {
    for k, v in local.fast_tenants : k => {
      access_policy = try(module.tenant-vpcsc-policy[k].id, null)
      automation = {
        federated_identity_pool      = null
        federated_identity_providers = local.identity_providers[k]
        outputs_bucket               = module.tenant-automation-tf-output-gcs[k].name
        project_id                   = module.tenant-automation-project[k].project_id
        project_number               = module.tenant-automation-project[k].number
        service_accounts = {
          resman   = module.tenant-automation-tf-resman-sa[k].email
          resman-r = module.tenant-automation-tf-resman-r-sa[k].email
        }
        tenant_service_accounts = {
          network    = module.tenant-automation-tf-network-sa[k].email
          security   = module.tenant-automation-tf-security-sa[k].email
          security-r = module.tenant-automation-tf-security-r-sa[k].email
        }
      }
      custom_roles = var.custom_roles
      logging = {
        log_sinks = {
          audit-logs = {
            filter = <<-FILTER
              log_id("cloudaudit.googleapis.com/activity") OR
              log_id("cloudaudit.googleapis.com/system_event") OR
              log_id("cloudaudit.googleapis.com/policy") OR
              log_id("cloudaudit.googleapis.com/access_transparency")
            FILTER
            type   = "logging"
          }
          vpc-sc = {
            filter = <<-FILTER
              protoPayload.metadata.@type="type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata"
            FILTER
            type   = "logging"
          }
        }
        project_id        = module.tenant-log-export-project[k].project_id
        project_number    = module.tenant-log-export-project[k].number
        writer_identities = {}
      }
      org_policy_tags = var.org_policy_tags
      root_node       = module.tenant-folder[k].id
      security = {
        access_policy_id = try(module.tenant-vpcsc-policy[k].id, null)
      }
    }
  }
}

output "tenants" {
  description = "Tenant base configuration."
  value       = local.tenant_data
}

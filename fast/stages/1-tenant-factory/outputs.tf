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
  tenant_data = {
    for k, v in local.tenants : k => {
      folder_id       = module.tenant-folder[k].id
      gcs_bucket      = module.tenant-gcs[k].id
      service_account = module.tenant-sa[k].email
    }
  }
  tenant_providers = {
    for k, v in local.fast_tenants : k => templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.tenant-automation-tf-resman-gcs[k].name
      name          = k
      sa            = module.tenant-automation-tf-resman-sa[k].name
    })
  }
  tenant_providers_r = {
    for k, v in local.fast_tenants : k => templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.tenant-automation-tf-resman-gcs[k].name
      name          = k
      sa            = module.tenant-automation-tf-resman-r-sa[k].name
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
      automation = {
        federated_identity_pool      = null
        federated_identity_providers = {}
        outputs_bucket               = module.tenant-automation-tf-output-gcs.name
        project_id                   = module.tenant-automation-project.project_id
        project_number               = module.tenant-automation-project.number
        service_accounts = {
          resman   = module.tenant-automation-tf-resman-sa.email
          resman-r = module.tenant-automation-tf-resman-r-sa.email
        }
      }
      custom_roles = var.custom_roles
      logging = {
        project_id        = module.tenant-log-export-project.project_id
        project_number    = module.tenant-log-export-project.number
        writer_identities = {}
      }
      org_policy_tags = var.org_policy_tags
    }
  }
}

output "tenants" {
  description = "Tenant base configuration."
  value       = local.tenant_data
}

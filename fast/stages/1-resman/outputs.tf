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
  folder_ids = merge(
    # stage 2
    !var.fast_stage_2.networking.enabled ? {} : {
      networking      = module.net-folder[0].id
      networking-dev  = try(module.net-folder-dev[0].id, null)
      networking-prod = try(module.net-folder-prod[0].id, null)
    },
    !var.fast_stage_2.security.enabled ? {} : {
      security      = module.sec-folder[0].id
      security-dev  = try(module.sec-folder-dev[0].id, null)
      security-prod = try(module.sec-folder-prod[0].id, null)
    },
    # stage 3
    { for k, v in module.stage3-folder : k => v.id },
    { for k, v in module.stage3-folder-dev : k => v.id },
    { for k, v in module.stage3-folder-prod : k => v.id },
    # top-level folders
    { for k, v in module.top-level-folder : k => v.id }
  )
  providers = merge(
    # stage 2
    !var.fast_stage_2.networking.enabled ? {} : {
      "2-networking" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.net-bucket[0].name
        name          = "networking"
        sa            = module.net-sa-rw[0].email
      })
      "2-networking-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.net-bucket[0].name
        name          = "networking"
        sa            = module.net-sa-ro[0].email
      })
    },
    !var.fast_stage_2.security.enabled ? {} : {
      "2-security" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.sec-bucket[0].name
        name          = "security"
        sa            = module.sec-sa-rw[0].email
      })
      "2-security-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.sec-bucket[0].name
        name          = "security"
        sa            = module.sec-sa-ro[0].email
      })
    },
    !var.fast_stage_2.project_factory.enabled ? {} : {
      "2-project-factory" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.pf-bucket[0].name
        name          = "project-factory"
        sa            = module.pf-sa-rw[0].email
      })
      "2-project-factory-r" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.pf-bucket[0].name
        name          = "project-factory"
        sa            = module.pf-sa-ro[0].email
      })
    },
    # stage 3
    {
      for k, v in var.fast_stage_3 :
      "3-${k}-prod" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage3-bucket-prod[k].name
        name          = "${k}-prod"
        sa            = module.stage3-sa-prod-rw[k].email
      })
    },
    {
      for k, v in var.fast_stage_3 :
      "3-${k}-dev" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.stage3-bucket-dev[k].name
        name          = "${k}-dev"
        sa            = module.stage3-sa-dev-rw[k].email
      }) if v.folder_config.create_env_folders
    },
    # top-level folders
    {
      for k, v in module.top-level-sa :
      "1-resman-folder-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.top-level-bucket[k].name
        name          = k
        sa            = v.email
      })
    },
  )
  service_accounts = merge(local.stage_service_accounts, {
    for k, v in module.top-level-sa : k => try(v.email)
  })
  tfvars = {
    checklist_hierarchy = local.checklist.hierarchy
    folder_ids          = local.folder_ids
    service_accounts    = local.service_accounts
    tag_keys            = { for k, v in try(local.tag_keys, {}) : k => v.id }
    tag_names           = var.tag_names
    tag_values          = { for k, v in try(local.tag_values, {}) : k => v.id }
  }
}

output "cicd_repositories" {
  description = "WIF configuration for CI/CD repositories."
  value = {
    for k, v in local.cicd_repositories : k => {
      repository = v.repository
      provider = try(
        local.identity_providers[v.identity_provider].name, null
      )
    }
  }
}

output "folder_ids" {
  description = "Folder ids."
  value       = local.folder_ids
}

# ready to use provider configurations for subsequent stages
output "providers" {
  # tfdoc:output:consumers 02-networking 02-security 03-dataplatform 03-network-security
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

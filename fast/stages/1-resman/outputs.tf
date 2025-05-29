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
  folder_ids = merge(
    # stage 2
    { for k, v in module.stage2-folder : k => v.id },
    { for k, v in module.stage2-folder-env : k => v.id },
    # stage 3
    { for k, v in module.stage3-folder : k => v.id },
    # top-level folders
    local.top_level_folder_ids
  )
  service_accounts = merge(
    local.stage_service_accounts,
    local.top_level_service_accounts
  )
  tfvars = {
    stage_configs = merge(
      {
        for k, v in local.stage3 : k => {
          environment = v.environment
          short_name  = v.short_name
        }
      },
      {
        for k, v in local.stage2 : k => {
          short_name = v.short_name
          iam_admin_delegated = {
            for kk in v.stage3_config.iam_admin_delegated :
            kk.environment => lookup(
              local.principals_iam, kk.principal, kk.principal
            )...
          }
          iam_viewer = {
            for kk in v.stage3_config.iam_viewer :
            kk.environment => lookup(
              local.principals_iam, kk.principal, kk.principal
            )...
          }
        }
      }
    )
    folder_ids       = local.folder_ids
    service_accounts = local.service_accounts
    tag_keys         = { for k, v in try(local.tag_keys, {}) : k => v.id }
    tag_names        = var.tag_names
    tag_values       = { for k, v in try(local.tag_values, {}) : k => v.id }
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
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

output "service_accounts" {
  description = "Service accounts."
  value       = local.service_accounts
}

output "tag_values" {
  description = "Tag values."
  value       = local.tfvars.tag_values
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

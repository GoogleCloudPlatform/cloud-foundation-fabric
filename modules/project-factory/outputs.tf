/**
 * Copyright 2025 Google LLC
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
  _outputs_automation_buckets = {
    for k, v in local.automation_buckets : v.parent_name => k
  }
  _outputs_automation_sas = {
    for k, v in local.automation_sas : v.parent_name => k...
  }
  outputs_projects = {
    for k, v in local.projects_input : k => {
      automation = {
        bucket = try(
          module.automation-bucket[local._outputs_automation_buckets[k]].name,
          null
        )
        service_accounts = {
          for sa in lookup(local._outputs_automation_sas, k, []) :
          sa => {
            email     = module.automation-service-accounts[sa].email
            iam_email = module.automation-service-accounts[sa].iam_email
            id        = module.automation-service-accounts[sa].id
          }
        }
      }
      number     = module.projects[k].number
      project_id = module.projects[k].project_id
      log_buckets = {
        for sk, sv in lookup(v, "log_buckets", {}) :
        "${k}/${sk}" => (
          module.log-buckets["${k}/${sk}"].id
        )
      }
      service_accounts = {
        for sk, sv in lookup(v, "service_accounts", {}) :
        "${k}/${sk}" => {
          email     = module.service-accounts["${k}/${sk}"].email
          iam_email = module.service-accounts["${k}/${sk}"].iam_email
          id        = module.service-accounts["${k}/${sk}"].id
        }
      }
      storage_buckets = {
        for sk, sv in lookup(v, "buckets", {}) :
        "${k}/${sk}" => (
          module.buckets["${k}/${sk}"].name
        )
      }
    }
  }
  outputs_service_accounts = merge(
    merge([
      for k, v in local.outputs_projects : v.service_accounts
    ]...),
    {
      for k, v in module.automation-service-accounts : k => {
        email     = v.email
        iam_email = v.iam_email
        id        = v.id
      }
    }
  )
}

output "folder_ids" {
  description = "Folder ids."
  value       = local.folder_ids
}

output "iam_principals" {
  description = "IAM principals mappings."
  value       = local.iam_principals
}

output "log_buckets" {
  description = "Log bucket ids."
  value = merge([
    for k, v in local.outputs_projects : v.log_buckets
  ]...)
}

output "project_ids" {
  description = "Project ids."
  value       = local.project_ids
}

output "project_numbers" {
  description = "Project numbers."
  value = {
    for k, v in local.outputs_projects : k => v.number
  }
}

output "projects" {
  description = "Project attributes."
  value       = local.outputs_projects
}

output "service_account_emails" {
  description = "Service account emails."
  value = {
    for k, v in local.outputs_service_accounts : k => v.email
  }
}

output "service_account_iam_emails" {
  description = "Service account IAM-format emails."
  value = {
    for k, v in local.outputs_service_accounts : k => v.iam_email
  }
}

output "service_account_ids" {
  description = "Service account IDs."
  value = {
    for k, v in local.outputs_service_accounts : k => v.id
  }
}

output "service_accounts" {
  description = "Service account emails."
  value       = local.outputs_service_accounts
}

output "storage_buckets" {
  description = "Bucket names."
  value = merge(
    merge([
      for k, v in local.outputs_projects : v.storage_buckets
    ]...),
    {
      for k, v in module.automation-bucket : k => v.name
    }
  )
}

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
  projects_log_buckets = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "log_buckets", {}) : {
        project_key  = k
        project_name = v.name
        name         = name
        description  = lookup(opts, "description", "Terraform-managed.")
        kms_key_name = lookup(opts, "kms_key_name", null)
        location = try(
          lookup(local.ctx.locations, opts.location, opts.location),
          "global"
        )
        retention     = lookup(v, "retention", null)
        log_analytics = lookup(v, "log_analytics", {})
      }
    ]
  ])
}

module "log-buckets" {
  source = "../logging-bucket"
  for_each = {
    for k in local.projects_log_buckets : "${k.project_key}/${k.name}" => k
  }
  parent       = module.projects[each.value.project_key].project_id
  name         = each.value.name
  location     = each.value.location
  kms_key_name = each.value.kms_key_name
  context = merge(local.ctx, {
    folder_ids  = local.ctx_folder_ids
    project_ids = local.ctx_project_ids
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails
    )
  })
  retention     = each.value.retention
  log_analytics = each.value.log_analytics
}

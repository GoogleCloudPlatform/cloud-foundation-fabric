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
        description  = lookup(opts, "description", null)
        kms_key_name = lookup(opts, "kms_key_name", null)
        location = coalesce(
          local.data_defaults.overrides.locations.logging,
          lookup(opts, "location", null),
          local.data_defaults.defaults.locations.logging,
          "global"
        )
        locked        = lookup(opts, "locked", null)
        retention     = lookup(opts, "retention", null)
        log_analytics = lookup(opts, "log_analytics", {})
        tag_bindings  = lookup(opts, "tag_bindings", {})
        views         = lookup(opts, "views", {})
      }
    ]
  ])
  log_buckets = {
    for k, v in module.log-buckets : k => v.id
  }
}

module "log-buckets" {
  source = "../logging-bucket"
  for_each = {
    for k in local.projects_log_buckets : "${k.project_key}/${k.name}" => k
  }
  parent       = module.projects-iam[each.value.project_key].project_id
  name         = each.value.name
  description  = each.value.description
  location     = each.value.location
  kms_key_name = each.value.kms_key_name
  context = merge(local.ctx, {
    folder_ids = local.ctx_folder_ids
    tag_vars = {
      projects     = merge(try(local.ctx.tag_vars.projects, {}), local.tag_vars_projects)
      organization = try(local.ctx.tag_vars.organization, {})
    }
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      local.projects_service_agents,
      lookup(local.per_project_service_agents, each.value.project_key, {}),
      lookup(local.self_sas_iam_emails, each.value.project_key, {})
    )
    kms_keys    = merge(local.ctx.kms_keys, local.kms_keys, local.kms_autokeys)
    locations   = local.ctx.locations
    project_ids = local.ctx_project_ids
    tag_values  = local.ctx_tag_values
  })
  locked        = each.value.locked
  retention     = each.value.retention
  log_analytics = each.value.log_analytics
  tag_bindings  = each.value.tag_bindings
  views         = each.value.views
}

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
  projects_keyrings = flatten([
    for k, v in local.projects_input : [
      for name, opts in v.kms.keyrings : {
        project_key           = k
        project_name          = v.name
        name                  = name
        location              = opts.location
        iam                   = lookup(opts, "iam", {})
        iam_bindings          = lookup(opts, "iam_bindings", {})
        iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
        keys                  = lookup(opts, "keys", {})
      } if try(opts.location, null) != null
    ]
  ])
  projects_kms_keys = {
    for k, v in local.projects_input : k => merge([
      for kk, kv in v.kms.keyrings : {
        for key_k, key_v in module.kms["${k}/${kk}"].key_ids :
        "${k}/${kk}/${key_k}" => key_v if try(kv.location, null) != null
      }
    ]...)
  }
  kms_autokeys = merge([
    for k, v in module.projects : {
      for kk, kv in v.kms_autokeys : "autokey/${k}/${kk}" => v
    }
  ])
  kms_keys = merge([
    for k, v in local.projects_kms_keys : v
  ]...)
}

module "kms" {
  source = "../kms"
  for_each = {
    for k in local.projects_keyrings : "${k.project_key}/${k.name}" => k
  }
  project_id = module.projects[each.value.project_key].project_id
  keyring = {
    location = coalesce(
      local.data_defaults.overrides.locations.storage,
      lookup(each.value, "location", null),
      local.data_defaults.defaults.locations.storage
    )
    name = each.value.name
  }
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  keys                  = each.value.keys
  context = merge(local.ctx, {
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      lookup(local.self_sas_iam_emails, each.value.project_key, {}),
      local.projects_service_agents
    )
    locations   = local.ctx.locations
    project_ids = local.ctx_project_ids
  })
}

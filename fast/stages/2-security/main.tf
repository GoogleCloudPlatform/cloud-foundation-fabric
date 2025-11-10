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
  paths = {
    for k, v in var.factories_config : k => try(pathexpand(v), null)
  }
  _ctx = {
    for k, v in var.context : k => merge(
      v, try(local._defaults.context[k], {})
    )
  }
  # dereferencing for outputs bucket
  _ctx_buckets = {
    for k, v in local.ctx.storage_buckets : "$storage_buckets:${k}" => v
  }
  # fail if we have no valid defaults
  _defaults = yamldecode(file(local.paths.defaults))
  # extend context with our own data
  ctx = merge(local._ctx, {
    custom_roles = merge(var.custom_roles, local._ctx.custom_roles)
    folder_ids   = merge(var.folder_ids, local._ctx.folder_ids)
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        "service_accounts/${k}" => "serviceAccount:${v}"
      },
      local._ctx.iam_principals
    )
    project_ids       = merge(var.project_ids, local._ctx.project_ids)
    storage_buckets   = merge(var.storage_buckets, local._ctx.storage_buckets)
    tag_keys          = merge(var.tag_keys, local._ctx.tag_keys)
    tag_values        = merge(var.tag_values, local._ctx.tag_values)
    vpc_sc_perimeters = merge(var.perimeters, local._ctx.vpc_sc_perimeters)
  })
  # normalize defaults
  defaults = {
    folder_name = try(local._defaults.global.folder_id, "security")
    stage_name  = try(local._defaults.global.stage_name, "2-security")
  }
  output_files = {
    local_path = try(local._defaults.output_files.local_path, null)
    storage_bucket = try(
      local._ctx_buckets[local._defaults.output_files.storage_bucket],
      local._defaults.output_files.storage_bucket,
      null
    )
  }
  project_defaults = {
    defaults = merge(
      {
        billing_account = var.billing_account.id
        prefix          = var.prefix
      },
      lookup(var.folder_ids, local.defaults.folder_name, null) == null ? {} : {
        parent = lookup(var.folder_ids, local.defaults.folder_name, null)
      },
      try(local._defaults.projects.defaults, {})
    )
    overrides = try(local._defaults.projects.overrides, {})
  }
}

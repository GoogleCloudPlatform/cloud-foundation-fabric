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
  # fail if we have no valid defaults
  _defaults = yamldecode(file(local.paths.defaults))
  ctx = merge(var.context, {
    folder_ids = merge(
      var.folder_ids, var.context.folder_ids
    )
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        "service_accounts/${k}" => "serviceAccount:${v}"
      },
      var.context.iam_principals,
      try(local._defaults.context.iam_principals, {})
    )
    locations = merge(
      var.context.locations,
      try(local._defaults.context.locations, {})
    )
    perimeters  = merge(var.perimeters, var.context.vpc_sc_perimeters)
    project_ids = merge(var.project_ids, var.context.project_ids)
    tag_keys    = merge(var.tag_keys, var.context.tag_keys)
    tag_values  = merge(var.tag_values, var.context.tag_values)
  })
  defaults = {
    folder_name = try(local._defaults.global.folder_id, "security")
    stage_name  = try(local._defaults.global.stage_name, "2-security")
  }
  output_files = {
    local_path     = try(local._defaults.output_files.local_path, null)
    storage_bucket = try(local._defaults.output_files.storage_bucket, null)
    providers      = try(local._defaults.output_files.providers, {})
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

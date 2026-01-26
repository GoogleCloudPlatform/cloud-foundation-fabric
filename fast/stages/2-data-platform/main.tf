/**
 * Copyright 2026 Google LLC
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
  _context = {
    for k, v in var.context : k => merge(
      v, try(local._defaults.context[k], {})
    )
  }
  context = merge(local._context, {
    custom_roles = merge(var.custom_roles, local._context.custom_roles)
    folder_ids   = merge(var.folder_ids, local._context.folder_ids)
    iam_principals = merge(
      var.iam_principals,
      {
        for k, v in var.service_accounts :
        "service_accounts/${k}" => "serviceAccount:${v}"
      },
      local._context.iam_principals
    )
    project_ids       = merge(var.project_ids, local._context.project_ids)
    tag_values        = merge(var.tag_values, local._context.tag_values)
    vpc_sc_perimeters = merge(var.perimeters, local._context.vpc_sc_perimeters)
  })
  project_defaults = {
    defaults = merge(
      {
        billing_account = var.billing_account.id
        prefix          = var.prefix
      },
      try(local._defaults.projects.defaults, {})
    )
    overrides = try(local._defaults.projects.overrides, {})
  }
}

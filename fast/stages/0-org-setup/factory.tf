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
  factory_billing = (
    try(local.project_defaults.defaults.billing_account, null) != null ||
    try(local.project_defaults.overrides.billing_account, null) != null
  ) ? {} : { billing_account = local.defaults.billing_account }
  factory_parent = (
    try(local.project_defaults.defaults.parent, null) != null ||
    try(local.project_defaults.overrides.parent, null) != null
  ) ? {} : { parent = "organizations/${local.organization_id}" }
}

module "factory" {
  source = "../../../modules/project-factory"
  data_defaults = merge(
    local.project_defaults.defaults,
    local.factory_billing,
    local.factory_parent
  )
  data_overrides = local.project_defaults.overrides
  context = merge(local.ctx, {
    condition_vars = merge(local.ctx_condition_vars, {
      custom_roles = merge(
        try(local.ctx.condition_vars.custom_roles, {}),
        module.organization[0].custom_role_id
      )
    })
    custom_roles = merge(
      local.ctx.custom_roles,
      module.organization[0].custom_role_id
    )
    folder_ids = merge(
      local.ctx.folder_ids,
      lookup(local.ctx.folder_ids, "default", null) != null ? {} : {
        default = try(module.organization[0].id, null)
      }
    )
    iam_principals = local.iam_principals
    tag_values = merge(
      local.ctx.tag_values,
      local.org_tag_values
    )
  })
  factories_config = {
    folders           = var.factories_config.folders
    project_templates = var.factories_config.project_templates
    projects          = var.factories_config.projects
  }
}

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

# tfdoc:file:description Organization policies.

locals {
  # context tag values for enabled stage 2s (merged in the final map below)
  _context_tag_values_stage2 = {
    for k, v in local.stage2 : k => replace(k, "_", "-")
  }
  # merge all context tag values into a single map
  context_tag_values = merge(
    # user-defined
    try(local.tags["context"]["values"], {}),
    # top-level folders
    {
      for k, v in local.top_level_folders : k => {
        iam         = try(local.tags.context.values.iam[k], {})
        description = try(local.tags.context.values.description[k], null)
      } if v.is_fast_context == true
    },
    # stage 2s
    {
      for k, v in local._context_tag_values_stage2 : v => {
        iam         = try(local.tags.context.values.iam[v], {})
        description = try(local.tags.context.values.description[v], null)
      }
    },
    # stage 3 define no context as they attach to a top-level folder
  )
  # environment tag values and their IAM bindings for stage 2 service accounts
  environment_tag_values = {
    for k, v in var.environments : v.tag_name => {
      iam = merge(
        # user-defined configuration
        try(local.tags.environment.values[v.tag_name].iam, {}),
        # stage 2 service accounts
        {
          "roles/resourcemanager.tagUser" = distinct(concat(
            try(local.tags.environment.values[v.tag_name].iam["roles/resourcemanager.tagUser"], []),
            [for k, v in module.stage2-sa-rw : v.iam_email]
          ))
          "roles/resourcemanager.tagViewer" = distinct(concat(
            try(local.tags.environment.values[v.tag_name].iam["roles/resourcemanager.tagViewer"], []),
            [for k, v in module.stage2-sa-ro : v.iam_email]
          ))
        }
      )
      description = try(
        local.tags.environment.values[v].description, null
      )
    }
  }
  # combine org-level IAM additive from billing and stage 2s
  iam_bindings_additive = merge(
    merge([
      for k, v in local.stage2 :
      v.organization_config.iam_bindings_additive
    ]...),
    local.billing_mode != "org" ? {} : local.billing_iam
  )
  # IAM principal expansion for user-specified tag values
  tags = {
    for k, v in var.tags : k => merge(v, {
      values = {
        for vk, vv in v.values : vk => merge(vv, {
          iam = {
            for rk, rv in vv.iam : rk => [
              for rm in rv : lookup(local.principals_iam, rm, rm)
            ]
          }
        })
      }
    })
  }
}

module "organization" {
  source          = "../../../modules/organization"
  count           = var.root_node == null ? 1 : 0
  organization_id = "organizations/${var.organization.id}"
  # additive bindings leveraging the delegated IAM grant set in stage 0
  iam_bindings_additive = {
    for k, v in local.iam_bindings_additive : k => {
      role      = lookup(var.custom_roles, v.role, v.role)
      member    = lookup(local.principals_iam, v.member, v.member)
      condition = v.condition
    }
  }
  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages
  tags = merge(local.tags, {
    (var.tag_names.context) = {
      description = "Resource management context."
      iam         = try(local.tags.context.iam, {})
      values      = local.context_tag_values
    },
    (var.tag_names.environment) = {
      description = "Environment definition."
      iam         = try(local.tags.environment.iam, {})
      values      = local.environment_tag_values
    }
  })
}

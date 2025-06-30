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

# tfdoc:file:description Organization-level tag locals.

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
  # organization policy tags managed in stage 0
  org_policy_tags = {
    for k, v in var.org_policy_tags.values :
    "${var.org_policy_tags.key_name}/${k}" => v
  }
  # context expansion for user-specified tag values
  tags = {
    for k, v in var.tags : k => merge(v, {
      iam = {
        for rk, rv in v.iam : rk => [
          for rm in rv : lookup(local.principals_iam, rm, rm)
        ]
      }
      id = (
        v.id == null || v.id != var.org_policy_tags.key_name
        ? v.id
        : var.org_policy_tags.key_id
      )
      values = {
        for vk, vv in v.values : vk => merge(vv, {
          iam = {
            for rk, rv in vv.iam : rk => [
              for rm in rv : try(
                local.principals_iam[rm],
                local.stage_service_accounts_iam[rm],
                rm
              )
            ]
          }
          id = (
            vv.id == null || v.id != var.org_policy_tags.key_name
            ? null
            : try(
              local.org_policy_tags["${var.org_policy_tags.key_name}/${vv.id}"],
              vv.id
            )
          )
        })
      }
    })
  }
}

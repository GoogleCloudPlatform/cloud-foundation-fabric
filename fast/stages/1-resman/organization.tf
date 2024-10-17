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
  _context_tag_values_stage2 = {
    for k, v in var.fast_stage_2 :
    k => replace(k, "_", "-") if v.enabled
  }
  context_tag_values = merge(
    try(local.tags["context"]["values"], {}),
    # top-level folders
    {
      for k, v in local.top_level_folders : v.context_name => {
        iam         = try(local.tags.context.values.iam[v.context_name], {})
        description = try(local.tags.context.values.description[v.context_name], null)
      } if v.context_name != null
    },
    # stage 2s
    {
      for k, v in local._context_tag_values_stage2 : v => {
        iam         = try(local.tags.context.values.iam[v], {})
        description = try(local.tags.context.values.description[v], null)
      }
    },
  )
  environment_tag_values = {
    for k, v in var.environment_names : v => {
      iam = merge(
        try(local.tags.environment.values[v].iam, {}),
        !var.fast_stage_2.project_factory.enabled
        ? {}
        : {
          "roles/resourcemanager.tagUser" = distinct(concat(
            try(local.tags.environment.values[v].iam["roles/resourcemanager.tagUser"], []),
            [module.pf-sa-rw[0].iam_email]
          ))
          "roles/resourcemanager.tagViewer" = distinct(concat(
            try(local.tags.environment.values[v].iam["roles/resourcemanager.tagViewer"], []),
            [module.pf-sa-ro[0].iam_email]
          ))
        }
      )
      description = try(
        local.tags.environment.values[v].description, null
      )
    }
  }
  # service accounts expansion for user-specified tag values
  tags = {
    for k, v in var.tags : k => merge(v, {
      values = {
        for vk, vv in v.values : vk => merge(vv, {
          iam = {
            for rk, rv in vv.iam : rk => [
              for rm in rv : (
                contains(keys(local.service_accounts), rm)
                ? "serviceAccount:${local.service_accounts[rm]}"
                : rm
              )
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
  # additive bindings via delegated IAM grant set in stage 0
  iam_bindings_additive = local.iam_bindings_additive
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

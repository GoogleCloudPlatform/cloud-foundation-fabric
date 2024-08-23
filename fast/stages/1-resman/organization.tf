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
  tag_values_stage2 = {
    for k, v in var.fast_stage_2 : k => replace(k, "_", "-") if v.enabled
  }
  tag_values_stage3 = {
    for k, v in var.fast_stage_3 : k => replace(k, "_", "-")
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
      values = merge(
        {
          for k, v in local.tag_values_stage2 : v => {
            iam         = try(local.tags.context.values.iam[v], {})
            description = try(local.tags.context.values.description[v], null)
          } if var.fast_stage_2[k].enabled
        },
        {
          for k, v in local.tag_values_stage3 : v => {
            iam         = try(local.tags.context.values.iam[v], {})
            description = try(local.tags.context.values.description[v], null)
          }
        }
      )
    },
    (var.tag_names.environment) = {
      description = "Environment definition."
      iam         = try(local.tags.environment.iam, {})
      values = {
        development = {
          iam = try(local.tags.environment.values.development.iam, {})
          iam_bindings = !var.fast_stage_2.project_factory.enabled ? {} : {
            pf = {
              members = [module.pf-sa-rw[0].iam_email]
              role    = "roles/resourcemanager.tagUser"
            }
          }
          description = try(
            local.tags.environment.values.development.description, null
          )
        }
        production = {
          iam = try(local.tags.environment.values.production.iam, {})
          iam_bindings = !var.fast_stage_2.project_factory.enabled ? {} : {
            pf = {
              members = [module.pf-sa-rw[0].iam_email]
              role    = "roles/resourcemanager.tagUser"
            }
          }
          description = try(
            local.tags.environment.values.production.description, null
          )
        }
      }
    }
  })
}

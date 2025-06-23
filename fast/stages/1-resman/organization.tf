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

# tfdoc:file:description Organization-level IAM and org policies.

locals {
  # combine org-level IAM additive from billing and stage 2s
  iam_bindings_additive = merge(
    merge([
      for k, v in local.stage2 :
      v.organization_config.iam_bindings_additive
    ]...),
    local.billing_mode != "org" ? {} : local.billing_iam
  )
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
      condition = lookup(v, "condition", null)
    }
  }
  factories_config = {
    tags = var.factories_config.tags
    context = {
      tag_keys   = var.factories_config.context.tag_keys
      tag_values = var.factories_config.context.tag_values
    }
  }
  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages
  tags = merge(local.tags, {
    (var.tag_names.context) = {
      description = try(local.tags[var.tag_names.context].description, "Resource management context.")
      iam         = try(local.tags[var.tag_names.context].iam, {})
      values      = local.context_tag_values
    },
    (var.tag_names.environment) = {
      description = try(local.tags[var.tag_names.environment].description, "Environment definition.")
      iam         = try(local.tags[var.tag_names.environment].iam, {})
      values      = local.environment_tag_values
    }
  })
}

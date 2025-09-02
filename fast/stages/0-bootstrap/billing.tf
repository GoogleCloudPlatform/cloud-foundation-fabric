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
  _billing_accounts_path = try(
    pathexpand(var.factories_config.billing_accounts), null
  )
  _billing_accounts_raw = {
    for f in try(fileset(local._billing_accounts_path, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => merge(
      { id = null },
      yamldecode(file("${local._billing_accounts_path}/${f}"))
    )
  }
  billing_accounts = {
    for k, v in local._billing_accounts_raw : k => merge(v, {
      id = (
        local.defaults.billing_account != null && v.id == "$defaults:billing_account"
        ? local.defaults.billing_account
        : v.id
      )
      logging_sinks = lookup(v, "logging_sinks", {})
    }) if v.id != null
  }
}

module "billing-accounts" {
  source   = "../../../modules/billing-account"
  for_each = local.billing_accounts
  id       = each.value.id
  context = merge(local.ctx, {
    custom_roles = merge(
      local.ctx.custom_roles, module.organization[0].custom_role_id
    )
    iam_principals = merge(
      local.ctx.iam_principals,
      module.factory.iam_principals
    )
    project_ids = merge(
      local.ctx.project_ids, module.factory.project_ids
    )
    storage_buckets = module.factory.storage_buckets
    tag_keys = merge(
      local.ctx.tag_keys,
      local.org_tag_keys
    )
    tag_values = merge(
      local.ctx.tag_values,
      local.org_tag_values
    )
  })
  iam                   = lookup(each.value, "iam", {})
  iam_by_principals     = lookup(each.value, "iam_by_principals", {})
  iam_bindings          = lookup(each.value, "iam_bindings", {})
  iam_bindings_additive = lookup(each.value, "iam_bindings_additive", {})
  logging_sinks = {
    for k, v in each.value.logging_sinks : k => v
    if lookup(v, "destination", null) != null && lookup(v, "type", null) != null
  }
}

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
  projects_bigquery_datasets = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "datasets", {}) : {
        project_key           = k
        project_name          = v.name
        id                    = name
        encryption_key        = lookup(opts, "encryption_key", null)
        friendly_name         = lookup(opts, "friendly_name", null)
        location              = lookup(opts, "location", null)
        iam                   = lookup(opts, "iam", {})
        iam_bindings          = lookup(opts, "iam_bindings", {})
        iam_bindings_additive = lookup(opts, "iam_bindings_additive", {})
        iam_by_principals     = lookup(opts, "iam_by_principals", {})
        tag_bindings          = lookup(opts, "tag_bindings", {})
        options = {
          default_collation               = try(opts.options.default_collation, null)
          default_table_expiration_ms     = try(opts.options.default_table_expiration_ms, null)
          default_partition_expiration_ms = try(opts.options.default_partition_expiration_ms, null)
          delete_contents_on_destroy      = try(opts.options.delete_contents_on_destroy, null)
          is_case_insensitive             = try(opts.options.is_case_insensitive, null)
          max_time_travel_hours           = try(opts.options.max_time_travel_hours, null)
          storage_billing_model           = try(opts.options.storage_billing_model, null)
        }
      }
    ]
  ])
}

module "bigquery-datasets" {
  source = "../bigquery-dataset"
  for_each = {
    for k in local.projects_bigquery_datasets : "${k.project_key}/${k.id}" => k
  }
  project_id = module.projects-iam[each.value.project_key].project_id
  id         = each.value.id
  context = merge(local.ctx, {
    iam_principals = merge(
      local.ctx.iam_principals,
      local.projects_sas_iam_emails,
      local.automation_sas_iam_emails,
      lookup(local.self_sas_iam_emails, each.value.project_key, {})
    )
    kms_keys    = merge(local.ctx.kms_keys, local.kms_keys, local.kms_autokeys)
    locations   = local.ctx.locations
    project_ids = local.ctx_project_ids
    tag_keys    = local.ctx_tag_keys
    tag_values  = local.ctx_tag_values
  })
  encryption_key = each.value.encryption_key
  friendly_name  = each.value.friendly_name
  location = coalesce(
    lookup(each.value, "location", null),
    local.data_defaults.defaults.locations.bigquery
  )
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  tag_bindings          = each.value.tag_bindings
  options               = each.value.options
}

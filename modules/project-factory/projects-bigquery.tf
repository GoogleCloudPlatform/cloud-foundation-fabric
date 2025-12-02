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
        project_key    = k
        project_name   = v.name
        id             = name
        encryption_key = lookup(opts, "encryption_key", null)
        friendly_name  = lookup(opts, "friendly_name", null)
        location       = lookup(opts, "location", null)
      }
    ]
  ])
}

module "bigquery-datasets" {
  source = "../bigquery-dataset"
  for_each = {
    for k in local.projects_bigquery_datasets : "${k.project_key}/${k.id}" => k
  }
  project_id = module.projects[each.value.project_key].project_id
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
  })
  encryption_key = each.value.encryption_key
  friendly_name  = each.value.friendly_name
  location = coalesce(
    local.data_defaults.overrides.locations.bigquery,
    lookup(each.value, "location", null),
    local.data_defaults.defaults.locations.bigquery
  )

  depends_on = [
    module.projects-iam
  ]
}

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

# tfdoc:file:description Phase 2: BigQuery datasets.

locals {
  _bigquery_raw = {
    for f in try(fileset(local.paths.bigquery, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.bigquery}/${f}")
    )
  }
}

module "bigquery" {
  source   = "../bigquery-dataset"
  for_each = local._bigquery_raw
  project_id          = try(each.value.project_id, null)
  id                  = try(each.value.id, each.key)
  description         = try(each.value.description, "Terraform managed.")
  friendly_name       = try(each.value.friendly_name, null)
  location            = try(each.value.location, "EU")
  labels              = try(each.value.labels, {})
  encryption_key      = try(each.value.encryption_key, null)
  options             = try(each.value.options, {})
  tables              = try(each.value.tables, {})
  views               = try(each.value.views, {})
  materialized_views  = try(each.value.materialized_views, {})
  routines            = try(each.value.routines, {})
  access              = try(each.value.access, {})
  access_identities   = try(each.value.access_identities, {})
  dataset_access      = try(each.value.dataset_access, false)
  tag_bindings        = try(each.value.tag_bindings, {})
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
  iam                   = try(each.value.iam, {})
  iam_bindings          = try(each.value.iam_bindings, {})
  iam_bindings_additive = try(each.value.iam_bindings_additive, {})
  iam_by_principals     = try(each.value.iam_by_principals, {})
}

/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Data Catalog Taxonomy definition

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p    = "$"
  location = try(local.ctx.locations[var.location], var.location)
  project_id = var.project_id == null ? null : lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
}

resource "google_data_catalog_taxonomy" "default" {
  provider               = google-beta
  project                = local.project_id
  region                 = local.location
  display_name           = var.name
  description            = var.description
  activated_policy_types = var.activated_policy_types
}

resource "google_data_catalog_policy_tag" "default" {
  provider     = google-beta
  for_each     = var.tags
  taxonomy     = google_data_catalog_taxonomy.default.id
  display_name = each.key
  description = coalesce(
    each.value.description, "${each.key} - Terraform managed."
  )
}

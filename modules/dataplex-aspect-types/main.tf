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
  _factory_path = try(pathexpand(var.factories_config.aspect_types), null)
  _factory_data_raw = {
    for f in try(fileset(local._factory_path, "**/*.yaml"), []) :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${local._factory_path}/${f}"))
  }
  aspect_types = merge(var.aspect_types, {
    for k, v in local._factory_data_raw : k => {
      description  = lookup(v, "description", null)
      display_name = lookup(v, "display_name", null)
      iam          = lookup(v, "iam", {})
      iam_bindings = {
        for ik, iv in lookup(v, "iam_bindings", {}) :
        ik => merge({ condition = null }, iv)
      }
      iam_bindings_additive = {
        for ik, iv in lookup(v, "iam_bindings_additive", {}) :
        ik => merge({ condition = null }, iv)
      }
      labels            = lookup(v, "labels", {})
      metadata_template = lookup(v, "metadata_template", null)
    }
  })
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

resource "google_dataplex_aspect_type" "default" {
  for_each          = local.aspect_types
  project           = local.project_id
  location          = local.location
  aspect_type_id    = each.key
  description       = each.value.description
  display_name      = each.value.display_name
  labels            = each.value.labels
  metadata_template = each.value.metadata_template
}

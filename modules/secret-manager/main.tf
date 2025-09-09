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
  # TODO: move tag template expansion in resources
  _tag_template_global = (
    "//secretmanager.googleapis.com/projects/%s/secrets/%s"
  )
  _tag_template_regional = (
    "//secretmanager.googleapis.com/projects/%s/locations/%s/secrets/%s"
  )
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p      = "$"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  tag_bindings = merge([
    for k, v in var.secrets : {
      for kk, vv in v.tag_bindings : "${k}/${kk}" => {
        location = v.location
        parent = (
          v.location == null
          ? format(
            local._tag_template_global,
            coalesce(var.project_number, var.project_id),
            google_secret_manager_secret.default[k].secret_id
          )
          : format(
            local._tag_template_regional,
            coalesce(var.project_number, var.project_id),
            lookup(local.ctx.locations, v.location, v.location),
            google_secret_manager_regional_secret.default[k].secret_id
          )
        )
        tag_value = vv
      }
    }
    if v.tag_bindings != null
  ]...)
}

# resource "google_kms_key_handle" "my_key_handle" {
#   provider               = google-beta
#   for_each               = var.kms_autokey_config
#   project                = var.project_id
#   name                   = each.key
#   location               = each.value
#   resource_type_selector = "secretmanager.googleapis.com/Secret"
# }

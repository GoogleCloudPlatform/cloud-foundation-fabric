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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p       = "$"
  project_id  = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  tag_project = coalesce(var.project_number, var.project_id)
  tag_bindings = merge([
    for k, v in var.secrets : {
      for kk, vv in v.tag_bindings : "${k}/${kk}" => {
        location = v.location
        secret   = k
        tag      = vv
      }
    }
    if v.tag_bindings != null
  ]...)
  versions = flatten([
    for k, v in var.secrets : [
      for sk, sv in v.versions : merge(sv, {
        secret   = k
        version  = sk
        location = v.location
      })
    ]
  ])
}

# resource "google_kms_key_handle" "my_key_handle" {
#   provider               = google-beta
#   for_each               = var.kms_autokey_config
#   project                = var.project_id
#   name                   = each.key
#   location               = each.value
#   resource_type_selector = "secretmanager.googleapis.com/Secret"
# }

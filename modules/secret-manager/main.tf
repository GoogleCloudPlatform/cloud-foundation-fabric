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
  _tag_template = (
    "//secretmanager.googleapis.com/projects/%s/secrets/%s"
  )
  tag_bindings = merge([
    for k, v in var.secrets : {
      for kk, vv in v.tag_bindings : "${k}/${kk}" => {
        parent = format(
          local._tag_template,
          coalesce(var.project_number, var.project_id),
          v.region == null
          ? google_secret_manager_secret.default[k].secret_id
          : google_secret_manager_regional_secret.default[k].secret_id
        )
        tag_value = vv
      }
    }
    if v.tag_bindings != null
  ]...)
}

resource "google_tags_tag_binding" "binding" {
  for_each  = local.tag_bindings
  parent    = each.value.parent
  tag_value = each.value.tag_value
}

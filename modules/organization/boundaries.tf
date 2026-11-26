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

# tfdoc:file:description Resource Manager boundaries and boundary configuration.

resource "google_resource_manager_boundary_config" "default" {
  count  = var.boundary_configs.tag_key == null ? 0 : 1
  parent = var.organization_id
  tag_key = templatestring(
    var.boundary_configs.tag_key, var.context.tag_vars
  )
  deletion_policy = var.boundary_configs.deletion_policy
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings,
    google_tags_tag_key.default,
  ]
}

resource "google_resource_manager_boundary" "default" {
  for_each        = coalesce(var.boundary_configs.boundaries, {})
  parent          = var.organization_id
  boundary_id     = each.key
  display_name    = each.value.display_name
  deletion_policy = each.value.deletion_policy
  dynamic "resource_filter" {
    for_each = each.value.tag_value == null ? [] : [""]
    content {
      tag_filter {
        tag_key   = google_resource_manager_boundary_config.default[0].tag_key
        tag_value = each.value.tag_value
      }
    }
  }
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings,
    google_resource_manager_boundary_config.default,
    google_tags_tag_value.default,
  ]
}

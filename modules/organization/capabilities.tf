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

# tfdoc:file:description Resource Manager capability configurations.

resource "google_resource_manager_capability_config" "default" {
  for_each             = var.capability_configs
  parent               = var.organization_id
  capability_config_id = each.key
  display_name         = each.value.display_name
  types                = each.value.types
  boundaries = (
    length(coalesce(each.value.boundaries, [])) == 0
    ? null
    : [
      for b in each.value.boundaries :
      contains(keys(coalesce(var.boundary_configs.boundaries, {})), b)
      ? google_resource_manager_boundary.default[b].name
      : b
    ]
  )
  management_project = (
    each.value.management_project == null
    ? null
    : try(
      "projects/${local.ctx.project_numbers[each.value.management_project]}",
      each.value.management_project
    )
  )
  deletion_policy = each.value.deletion_policy
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings,
  ]
}

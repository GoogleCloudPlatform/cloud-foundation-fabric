/**
 * Copyright 2024 Google LLC
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

moved {
  from = google_artifact_registry_repository_iam_binding.bindings
  to   = google_artifact_registry_repository_iam_binding.authoritative
}

resource "google_artifact_registry_repository_iam_binding" "authoritative" {
  provider   = google-beta
  for_each   = local.iam
  project    = local.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for member in each.value :
    lookup(local.ctx.iam_principals, member, member)
  ]
}

# renamed as bindings2 to allow the moved block above
resource "google_artifact_registry_repository_iam_binding" "bindings2" {
  for_each   = var.iam_bindings
  project    = local.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for member in each.value.members :
    lookup(local.ctx.iam_principals, member, member)
  ]

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "members" {
  for_each   = var.iam_bindings_additive
  project    = local.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member     = lookup(local.ctx.iam_principals, each.value.member, each.value.member)

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

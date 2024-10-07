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
  for_each   = local.iam
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = each.key
  members    = each.value
}

# renamed as bindings2 to allow the moved block above
resource "google_artifact_registry_repository_iam_binding" "bindings2" {
  for_each   = var.iam_bindings
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = each.value.role
  members    = each.value.members

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "members" {
  for_each   = var.iam_bindings_additive
  project    = var.project_id
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = each.value.role
  member     = each.value.member

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

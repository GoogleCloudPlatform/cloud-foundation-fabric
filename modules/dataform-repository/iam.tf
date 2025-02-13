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

resource "google_dataform_repository_iam_binding" "authoritative" {
  provider   = google-beta
  for_each   = var.iam
  role       = each.key
  members    = each.value
  repository = google_dataform_repository.default.name
}

resource "google_dataform_repository_iam_binding" "bindings" {
  provider   = google-beta
  for_each   = var.iam_bindings
  role       = each.value.role
  members    = each.value.members
  repository = google_dataform_repository.default.name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_dataform_repository_iam_member" "bindings" {
  provider   = google-beta
  for_each   = var.iam_bindings_additive
  role       = each.value.role
  member     = each.value.member
  repository = google_dataform_repository.default.name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

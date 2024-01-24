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

locals {
  repository_iam = flatten([
    for k, v in var.repository : [
      for role, members in v.iam : {
        key     = k
        role    = role
        members = members
      }
    ]
  ])
  repository_iam_bindings = merge([
    for k, v in var.repository : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        repository = k
        role       = data.role
        members    = data.members
        condition  = data.condition
      }
    }
  ]...)
  repository_iam_bindings_additive = merge([
    for k, v in var.repository : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        repository = k
        role       = data.role
        member     = data.member
        condition  = data.condition
      }
    }
  ]...)
}

resource "google_dataform_repository_iam_binding" "authoritative" {
  provider = google-beta
  for_each = {
    for binding in local.repository_iam :
    "${binding.key}.${binding.role}" => binding
  }
  role       = each.value.role
  members    = each.value.members
  repository = google_dataform_repository.default[each.value.key].name

}

resource "google_dataform_repository_iam_binding" "bindings" {
  provider   = google-beta
  for_each   = local.repository_iam_bindings
  role       = each.value.role
  members    = each.value.members
  repository = google_dataform_repository.default[each.value.key].name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_dataform_repository_iam_member" "members" {
  provider   = google-beta
  for_each   = local.repository_iam_bindings_additive
  role       = each.value.role
  member     = each.value.member
  repository = google_dataform_repository.default[each.value.key].name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

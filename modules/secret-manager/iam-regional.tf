/**
 * Copyright 2023 Google LLC
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

resource "google_secret_manager_regional_secret_iam_binding" "authoritative" {
  for_each = {
    for binding in local.secret_iam :
    "${binding.secret}.${binding.role}" => binding if !binding.global
  }
  role      = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  secret_id = google_secret_manager_regional_secret.default[each.value.secret].id
  location  = google_secret_manager_regional_secret.default[each.value.secret].location
  members = [
    for v in each.value.members :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_secret_manager_regional_secret_iam_binding" "bindings" {
  for_each = {
    for k, v in local.secret_iam_bindings : k => v if !v.global
  }
  role      = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  secret_id = google_secret_manager_regional_secret.default[each.value.secret].id
  location  = google_secret_manager_regional_secret.default[each.value.secret].location
  members = [
    for v in each.value.members :
    lookup(local.ctx.iam_principals, v, v)
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

resource "google_secret_manager_regional_secret_iam_member" "members" {
  for_each = {
    for k, v in local.secret_iam_bindings_additive : k => v if !v.global
  }
  secret_id = google_secret_manager_regional_secret.default[each.value.secret].id
  location  = google_secret_manager_regional_secret.default[each.value.secret].location
  role      = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member    = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
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

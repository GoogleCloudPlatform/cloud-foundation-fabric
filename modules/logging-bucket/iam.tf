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
  view_iam = flatten([
    for k, v in var.views : [
      for role, members in v.iam : {
        view    = k
        role    = role
        members = members
      }
    ]
  ])
  view_iam_bindings = merge([
    for k, v in var.views : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        view      = k
        role      = data.role
        members   = data.members
        condition = data.condition
      }
    }
  ]...)
  view_iam_bindings_additive = merge([
    for k, v in var.views : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        view      = k
        role      = data.role
        member    = data.member
        condition = data.condition
      }
    }
  ]...)
}

resource "google_logging_log_view_iam_binding" "authoritative" {
  for_each = {
    for binding in local.view_iam :
    "${binding.view}.${binding.role}" => binding
  }
  role = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  parent   = google_logging_log_view.views[each.value.view].parent
  location = google_logging_log_view.views[each.value.view].location
  bucket   = google_logging_log_view.views[each.value.view].bucket
  name     = google_logging_log_view.views[each.value.view].name
}

resource "google_logging_log_view_iam_binding" "bindings" {
  for_each = local.view_iam_bindings
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
  parent   = google_logging_log_view.views[each.value.view].parent
  location = google_logging_log_view.views[each.value.view].location
  bucket   = google_logging_log_view.views[each.value.view].bucket
  name     = google_logging_log_view.views[each.value.view].name

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_logging_log_view_iam_member" "members" {
  for_each = local.view_iam_bindings_additive
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member   = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
  parent   = google_logging_log_view.views[each.value.view].parent
  location = google_logging_log_view.views[each.value.view].location
  bucket   = google_logging_log_view.views[each.value.view].bucket
  name     = google_logging_log_view.views[each.value.view].name
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

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

locals {
  iam = flatten([
    for k, v in local.aspect_types : [
      for role, members in v.iam : {
        aspect_type_id = k
        role           = role
        members        = members
      }
    ]
  ])
  iam_bindings = merge([
    for k, v in local.aspect_types : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        aspect_type_id = k
        role           = data.role
        members        = data.members
        condition      = data.condition
      }
    }
  ]...)
  iam_bindings_additive = merge([
    for k, v in local.aspect_types : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        aspect_type_id = k
        role           = data.role
        member         = data.member
        condition      = data.condition
      }
    }
  ]...)
}

resource "google_dataplex_aspect_type_iam_binding" "authoritative" {
  for_each = {
    for binding in local.iam :
    "${binding.aspect_type_id}.${binding.role}" => binding
  }
  role           = each.value.role
  aspect_type_id = google_dataplex_aspect_type.default[each.value.aspect_type_id].id
  members = [
    for v in each.value.members :
    lookup(var.factories_config.context.iam_principals, v, v)
  ]
}

resource "google_dataplex_aspect_type_iam_binding" "bindings" {
  for_each       = local.iam_bindings
  role           = each.value.role
  aspect_type_id = google_dataplex_aspect_type.default[each.value.aspect_type_id].id
  members = [
    for v in each.value.members :
    lookup(var.factories_config.context.iam_principals, v, v)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_dataplex_aspect_type_iam_member" "members" {
  for_each       = local.iam_bindings_additive
  aspect_type_id = google_dataplex_aspect_type.default[each.value.aspect_type_id].id
  role           = each.value.role
  member = lookup(
    var.factories_config.context.iam_principals, each.value.member, each.value.member
  )
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

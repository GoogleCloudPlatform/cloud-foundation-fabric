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

# tfdoc:file:description IAM bindings

locals {
  tt_iam = flatten([
    for k, v in local.tag_templates : [
      for role, members in v.iam : {
        key     = k
        role    = role
        members = members
      }
    ]
  ])
  tt_iam_bindings = merge([
    for k, v in local.tag_templates : {
      for binding_key, data in v.iam_bindings :
      binding_key => {
        key       = k
        role      = data.role
        members   = data.members
        condition = data.condition
      }
    }
  ]...)
  tt_iam_bindings_additive = merge([
    for k, v in local.tag_templates : {
      for binding_key, data in v.iam_bindings_additive :
      binding_key => {
        key       = k
        role      = data.role
        member    = data.member
        condition = data.condition
      }
    }
  ]...)
}

resource "google_data_catalog_tag_template_iam_binding" "authoritative" {
  for_each = {
    for binding in local.tt_iam :
    "${binding.key}.${binding.role}" => binding
  }
  tag_template = google_data_catalog_tag_template.default[each.value.key].id
  role         = each.value.role
  members      = each.value.members
}

resource "google_data_catalog_tag_template_iam_binding" "bindings" {
  for_each     = local.tt_iam_bindings
  tag_template = google_data_catalog_tag_template.default[each.value.key].id
  role         = each.value.role
  members      = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_data_catalog_tag_template_iam_member" "bindings" {
  for_each     = local.tt_iam_bindings_additive
  tag_template = google_data_catalog_tag_template.default[each.value.key].id
  role         = each.value.role
  member       = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

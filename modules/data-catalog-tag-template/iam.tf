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
  iam_template_map = {
    for binding in flatten([
      for role, members in var.iam : [
        for template_k, template_v in google_data_catalog_tag_template.tag_template : {
          template = template_v,
          role     = role,
          members  = members
        }
      ]
    ]) : "${binding.template.tag_template_id}-${binding.role}" => binding
  }

  iam_bindings_template_map = {
    for binding in flatten([
      for iam_bindings_k, iam_bindings_v in var.iam_bindings : [
        for template_k, template_v in google_data_catalog_tag_template.tag_template : {
          template         = template_v,
          iam_bindings_key = iam_bindings_k,
          role             = iam_bindings_v.role,
          member           = iam_bindings_v.members,
          condition        = iam_bindings_v.condition
        }
      ]
    ]) : "${binding.template.tag_template_id}-${binding.iam_bindings_key}" => binding
  }

  iam_bindings_additive_template_map = {
    for binding in flatten([
      for iam_bindings_k, iam_bindings_v in var.iam_bindings_additive : [
        for template_k, template_v in google_data_catalog_tag_template.tag_template : {
          template       = template_v,
          iam_bindings_k = iam_bindings_k,
          role           = iam_bindings_v.role,
          member         = iam_bindings_v.member,
          condition      = iam_bindings_v.condition
        }
      ]
    ]) : "${binding.template.tag_template_id}-${binding.iam_bindings_k}" => binding
  }
}

resource "google_data_catalog_tag_template_iam_binding" "authoritative" {
  for_each     = local.iam_template_map
  tag_template = each.value.template.id
  role         = each.value.role
  members      = each.value.members
}

resource "google_data_catalog_tag_template_iam_binding" "bindings" {
  for_each     = local.iam_bindings_template_map
  tag_template = each.value.template.id
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
  for_each     = local.iam_bindings_additive_template_map
  tag_template = each.value.template.id
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

/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Data Catalog Taxonomy IAM definition.

locals {
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }
  tags_iam = flatten([
    for k, v in var.tags : [
      for role, members in v.iam : {
        tag     = k
        role    = role
        members = members
      }
    ]
  ])
}

resource "google_data_catalog_taxonomy_iam_binding" "authoritative" {
  provider = google-beta
  for_each = local.iam
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = each.key
  members  = each.value
}

resource "google_data_catalog_taxonomy_iam_binding" "bindings" {
  provider = google-beta
  for_each = var.iam_bindings
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = each.value.role
  members  = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_data_catalog_taxonomy_iam_member" "bindings" {
  provider = google-beta
  for_each = var.iam_bindings_additive
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = each.value.role
  member   = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_data_catalog_policy_tag_iam_binding" "authoritative" {
  provider = google-beta
  for_each = {
    for v in local.tags_iam : "${v.tag}.${v.role}" => v
  }
  policy_tag = google_data_catalog_policy_tag.default[each.value.tag].name
  role       = each.value.role
  members    = each.value.members
}

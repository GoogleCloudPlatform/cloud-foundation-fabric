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
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(
      keys(var.iam),
      keys(local._iam_principals),
      keys(try(local._factory_data.iam, {}))
    )) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], []),
      try(local._factory_data.iam[role], [])
    )
  }
  iam_bindings = merge(
    var.iam_bindings,
    {
      for k, v in try(local._factory_data.iam_bindings, {}) : k => merge(v, {
        condition = try(v.condition, null)
      })
    }
  )
  iam_bindings_additive = merge(
    var.iam_bindings_additive,
    {
      for k, v in try(local._factory_data.iam_bindings_additive, {}) : k => merge(v, {
        condition = try(v.condition, null)
      })
    }
  )
  tags_iam = flatten([
    for k, v in local.tags : [
      for role, members in v.iam : {
        tag     = k
        role    = role
        members = members
      }
    ]
  ])
  tags_iam_bindings = merge([
    for k, v in local.tags : {
      for bk, bv in v.iam_bindings : "${k}.${bk}" => merge(bv, {
        tag = k
        key = bk
      })
    }
  ]...)
  tags_iam_bindings_additive = merge([
    for k, v in local.tags : {
      for bk, bv in v.iam_bindings_additive : "${k}.${bk}" => merge(bv, {
        tag = k
        key = bk
      })
    }
  ]...)
}

resource "google_data_catalog_taxonomy_iam_binding" "authoritative" {
  provider = google-beta
  for_each = local.iam
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_data_catalog_taxonomy_iam_binding" "bindings" {
  provider = google-beta
  for_each = local.iam_bindings
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
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

resource "google_data_catalog_taxonomy_iam_member" "bindings" {
  provider = google-beta
  for_each = local.iam_bindings_additive
  taxonomy = google_data_catalog_taxonomy.default.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member   = lookup(local.ctx.iam_principals, each.value.member, each.value.member)
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

resource "google_data_catalog_policy_tag_iam_binding" "authoritative" {
  provider = google-beta
  for_each = {
    for v in local.tags_iam : "${v.tag}.${v.role}" => v
  }
  policy_tag = google_data_catalog_policy_tag.default[each.value.tag].name
  role       = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members :
    lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_data_catalog_policy_tag_iam_binding" "bindings" {
  provider   = google-beta
  for_each   = local.tags_iam_bindings
  policy_tag = google_data_catalog_policy_tag.default[each.value.tag].name
  role       = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
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

resource "google_data_catalog_policy_tag_iam_member" "bindings" {
  provider   = google-beta
  for_each   = local.tags_iam_bindings_additive
  policy_tag = google_data_catalog_policy_tag.default[each.value.tag].name
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

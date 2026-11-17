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

# tfdoc:file:description IAM bindings.

locals {
  _db_iam_roles = {
    for k, v in var.databases :
    k => distinct(concat(keys(v.iam), flatten(values(v.iam_by_principals))))
  }
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  spanner_database_iam = merge([
    for k1, v1 in var.databases : {
      for role in local._db_iam_roles[k1] :
      "${k1}.${role}" => {
        database = k1
        role     = role
        members = concat(
          try(v1.iam[role], []),
          [
            for k2, v2 in v1.iam_by_principals :
            k2 if try(index(v2, role), null) != null
          ]
        )
      }
    }
  ]...)
  spanner_database_iam_bindings = merge([
    for k1, v1 in var.databases : {
      for k2, v2 in v1.iam_bindings :
      "${k1}.${k2}" => merge(v2, {
        database = k1
      })
    }
  ]...)
  spanner_database_iam_bindings_additive = merge([
    for k1, v1 in var.databases : {
      for k2, v2 in v1.iam_bindings_additive :
      "${k1}.${k2}" => merge(v2, {
        database = k1
      })
    }
  ]...)
}

resource "google_spanner_instance_iam_binding" "authoritative" {
  for_each = local.iam
  project  = local.spanner_instance.project
  instance = local.spanner_instance.id
  role     = lookup(local.ctx.custom_roles, each.key, each.key)
  members = [
    for v in each.value : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_spanner_instance_iam_binding" "bindings" {
  for_each = var.iam_bindings
  project  = local.spanner_instance.project
  instance = local.spanner_instance.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
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

resource "google_spanner_instance_iam_member" "bindings" {
  for_each = var.iam_bindings_additive
  project  = local.spanner_instance.project
  instance = local.spanner_instance.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
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

resource "google_spanner_database_iam_binding" "authoritative" {
  for_each = local.spanner_database_iam
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_spanner_database_iam_binding" "bindings" {
  for_each = local.spanner_database_iam_bindings
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
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

resource "google_spanner_database_iam_member" "bindings" {
  for_each = local.spanner_database_iam_bindings_additive
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
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

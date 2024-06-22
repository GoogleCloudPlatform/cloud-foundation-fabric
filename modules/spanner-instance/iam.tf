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
  spanner_database_iam = merge([for k1, v1 in var.databases : { for k2, v2 in v1.iam :
    "${k1}.${k2}" => {
      database = k1
      role     = k2
      members  = v2
  } }]...)
  spanner_database_iam_bindings = merge([for k1, v1 in var.databases : { for k2, v2 in v1.iam_bindings :
    "${k1}.${k2}" => merge(v2, {
      database = k1
  }) }]...)
  spanner_database_iam_bindings_additive = merge([for k1, v1 in var.databases : { for k2, v2 in v1.iam_bindings_additive :
    "${k1}.${k2}" => merge(v2, {
      database = k1
  }) }]...)
}

resource "google_spanner_instance_iam_binding" "authoritative" {
  for_each = var.iam
  project  = local.spanner_instance.project
  instance = local.spanner_instance.id
  role     = each.key
  members  = each.value
}

resource "google_spanner_instance_iam_binding" "bindings" {
  for_each = var.iam_bindings
  project  = local.spanner_instance.project
  instance = local.spanner_instance.id
  role     = each.value.role
  members  = each.value.members
}

resource "google_spanner_instance_iam_member" "bindings" {
  for_each = var.iam_bindings_additive
  project  = var.project_id
  instance = local.spanner_instance.id
  role     = each.value.role
  member   = each.value.member
}

resource "google_spanner_database_iam_binding" "authoritative" {
  for_each = local.spanner_database_iam
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
  role     = each.value.role
  members  = each.value.members
}

resource "google_spanner_database_iam_binding" "bindings" {
  for_each = local.spanner_database_iam_bindings
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
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

resource "google_spanner_database_iam_member" "bindings" {
  for_each = local.spanner_database_iam_bindings_additive
  project  = google_spanner_database.spanner_databases[each.value.database].project
  instance = google_spanner_database.spanner_databases[each.value.database].instance
  database = google_spanner_database.spanner_databases[each.value.database].name
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

/**
 * Copyright 2025 Google LLC
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
}

resource "google_bigquery_connection_iam_binding" "authoritative" {
  for_each      = local.iam
  project       = google_bigquery_connection.connection.project
  location      = google_bigquery_connection.connection.location
  connection_id = google_bigquery_connection.connection.connection_id
  role          = each.key
  members       = each.value
}

resource "google_bigquery_connection_iam_binding" "bindings" {
  for_each      = var.iam_bindings
  project       = google_bigquery_connection.connection.project
  location      = google_bigquery_connection.connection.location
  connection_id = google_bigquery_connection.connection.connection_id
  role          = each.value.role
  members       = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_bigquery_connection_iam_member" "bindings" {
  for_each      = var.iam_bindings_additive
  project       = google_bigquery_connection.connection.project
  location      = google_bigquery_connection.connection.location
  connection_id = google_bigquery_connection.connection.connection_id
  role          = each.value.role
  member        = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

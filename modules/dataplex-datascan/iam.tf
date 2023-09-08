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
  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }
}

resource "google_dataplex_datascan_iam_binding" "authoritative_for_role" {
  for_each     = local.iam
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
  role         = each.key
  members      = each.value
}

resource "google_dataplex_datascan_iam_binding" "bindings" {
  for_each     = var.iam_bindings
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
  role         = each.value.role
  members      = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_dataplex_datascan_iam_member" "bindings" {
  for_each     = var.iam_bindings_additive
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
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

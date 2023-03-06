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

# # tfdoc:file:description Generic IAM bindings and roles.

locals {
  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  _iam_additive_pairs = flatten([
    for role, members in var.iam_additive : [
      for member in members : { role = role, member = member }
    ]
  ])
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }
  iam_additive = {
    for pair in local._iam_additive_pairs :
    "${pair.role}-${pair.member}" => {
      role   = pair.role
      member = pair.member
    }
  }
}

resource "google_dataproc_cluster_iam_binding" "authoritative" {
  for_each = local.iam
  project  = var.project_id
  cluster  = google_dataproc_cluster.cluster.name
  region   = var.region
  role     = each.key
  members  = each.value
}

resource "google_dataproc_cluster_iam_member" "additive" {
  for_each = (
    length(var.iam_additive) > 0
    ? local.iam_additive
    : {}
  )
  project = var.project_id
  cluster = google_dataproc_cluster.cluster.name
  region  = var.region
  role    = each.value.role
  member  = each.value.member
}

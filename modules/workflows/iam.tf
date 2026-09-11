# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  _iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  _iam_members = flatten([
    for role, members in local._iam : [
      for member in members : {
        role   = role
        member = member
      }
    ]
  ])
  iam = {
    for m in local._iam_members : "${m.role}:${m.member}" => m
  }
}

resource "google_project_iam_member" "default" {
  for_each = local.iam
  project  = local.project_id
  role     = each.value.role
  member   = each.value.member
}

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
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
  _sa_members = flatten([
    for k, v in var.service_account_impersonation : [
      for idx, m in concat(
        [
          for s in coalesce(v.subjects, []) :
          "principal://iam.googleapis.com/${local.pool_name}/subject/${s}"
        ],
        [
          for a in coalesce(v.attribute_members, []) :
          "principalSet://iam.googleapis.com/${local.pool_name}/${a}"
        ]
        ) : {
        key = "${k}:${idx}"
        service_account_id = (
          startswith(
            lookup(
              local.ctx.service_accounts,
              v.service_account_id,
              v.service_account_id
            ),
            "projects/"
          )
          ? lookup(
            local.ctx.service_accounts,
            v.service_account_id,
            v.service_account_id
          )
          : format(
            "projects/%s/serviceAccounts/%s",
            local.project_id,
            lookup(
              local.ctx.service_accounts,
              v.service_account_id,
              v.service_account_id
            )
          )
        )
        member = m
      }
    ]
  ])
  sa_members = { for item in local._sa_members : item.key => item }
}

resource "google_iam_workload_identity_pool_iam_binding" "default" {
  for_each = local.iam
  provider = google
  project  = local.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.default.workload_identity_pool_id
  )
  role    = each.key
  members = each.value
}

resource "google_service_account_iam_member" "impersonation" {
  for_each           = local.sa_members
  provider           = google
  service_account_id = each.value.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.member
}

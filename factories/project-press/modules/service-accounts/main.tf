/**
 * Copyright 2021 Google LLC
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
  service_accounts = [for env in var.environments : { for sa in var.service_accounts :
    format("%s-%s", env, sa.name) => merge({ env = env }, sa)
  }]

  service_account_permissions = [for k, sa in merge(local.service_accounts...) :
    [for role in sa.roles :
      { for permission in var.service_account_roles[role].permissions : format("%s-%s-%s", k, role, permission) =>
        {
          service_account = k
          permission      = permission
          env             = sa.env
        }
      }
    ]
  ]

  service_account_additional_permissions = [for k, sa in merge(local.service_accounts...) :
    { for permission in lookup(sa, "additionalIamRoles", []) : format("%s-%s", k, permission) =>
      {
        service_account = k
        permission      = permission
        env             = sa.env
      }
    }
  ]

  service_account_actas = [for k, sa in merge(local.service_accounts...) :
    [for role in sa.roles :
      [for groups in var.project_groups[sa.env] :
        { for gk, group in groups : format("%s-%s-%s", k, role, group.id) =>
          {
            service_account = k
            group           = group
            env             = sa.env
          }
        }
      ] if lookup(var.service_account_roles[role], "actAs", false) != false
    ]
  ]
}

resource "google_service_account" "service-account" {
  for_each = length(var.service_accounts) > 0 ? merge(local.service_accounts...) : {}

  project = var.project_ids_full[each.value.env]

  account_id   = each.value.name
  display_name = lookup(each.value, "displayName", "") != "" ? each.value.displayName : title(each.value.name)
  description  = lookup(each.value, "description", "") != "" ? each.value.description : "Created by Turbo Project Factory"
}

resource "google_project_iam_member" "service-account-permissions" {
  for_each = length(var.service_accounts) > 0 ? merge(flatten(local.service_account_permissions)...) : {}

  project = var.project_ids_full[each.value.env]
  role    = each.value.permission

  member = format("serviceAccount:%s", google_service_account.service-account[each.value.service_account].email)
}

resource "google_project_iam_member" "service-account-additional-permissions" {
  for_each = length(var.service_accounts) > 0 ? merge(flatten(local.service_account_additional_permissions)...) : {}

  project = var.project_ids_full[index(var.environments, each.value.env)]
  role    = each.value.permission

  member = format("serviceAccount:%s", google_service_account.service-account[each.value.service_account].email)
}

resource "google_service_account_iam_member" "service-account-actas-permissions" {
  for_each = length(flatten(local.service_account_actas)) > 0 ? merge(flatten(local.service_account_actas)...) : {}

  service_account_id = google_service_account.service-account[each.value.service_account].name
  role               = "roles/iam.serviceAccountUser"

  member = format("group:%s", each.value.group.id)
}

resource "google_cloud_identity_group_membership" "service-account-group-membership" {
  provider = google-beta
  for_each = var.only_add_permissions || length(var.service_accounts) == 0 ? {} : merge(local.service_accounts...)

  group = var.sa_groups[each.value.env]

  member_key {
    id = google_service_account.service-account[each.key].email
  }

  roles {
    name = "MEMBER"
  }
}

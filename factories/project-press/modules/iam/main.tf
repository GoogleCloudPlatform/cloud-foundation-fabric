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

/**
 * Add permissions to a project group 
 **/
locals {
  permissions            = { for index, group in setproduct(var.environments, distinct(var.project_permissions)) : "${var.group}-${group[0]}-${group[1]}" => group }
  compute_sa_permissions = { for index, group in setproduct(var.environments, distinct(var.compute_sa_permissions)) : "${var.group}-${group[0]}-${group[1]}" => group }
  project_sa_permissions = { for index, group in setproduct(var.environments, distinct(var.project_sa_permissions)) : "${var.group}-${group[0]}-${group[1]}" => group }
  extra_permissions = [for env in var.environments :
    { for permission in lookup(var.extra_permissions, env, []) :
      "${var.group}-${env}-${permission}" => [env, permission]
    }
  ]
  additional_roles = merge(flatten([for env in var.environments :
    [for role in var.additional_roles :
      { for perm in var.additional_roles_config[role].permissions : "${var.group}-${env}-${perm}" => [env, perm]
      }
    ]
  ])...)
  additional_iam_roles = { for index, group in setproduct(var.environments, distinct(var.additional_iam_roles)) : "${var.group}-${group[0]}-${group[1]}" => group }
}

/**
 * Add correct permissions to project groups
 */
resource "google_project_iam_member" "project_permissions" {
  for_each = local.permissions

  project = var.project_ids_full[each.value[0]]
  role    = each.value[1]

  member = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}

resource "google_project_iam_member" "project_extra_permissions" {
  for_each = merge(local.extra_permissions...)

  project = var.project_ids_full[each.value[0]]
  role    = each.value[1]

  member = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}

resource "google_service_account_iam_member" "compute_sa_permission" {
  for_each = local.compute_sa_permissions

  service_account_id = format("projects/%s/serviceAccounts/%s", var.project_ids_full[each.value[0]], var.service_accounts.compute[each.value[0]])
  role               = each.value[1]
  member             = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}

resource "google_service_account_iam_member" "project_sa_permission" {
  for_each = local.project_sa_permissions

  service_account_id = format("projects/%s/serviceAccounts/%s", var.project_ids_full[each.value[0]], var.service_accounts.project[each.value[0]])
  role               = each.value[1]
  member             = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}


resource "google_project_iam_member" "project_additional_roles" {
  for_each = local.additional_roles
  project  = var.project_ids_full[each.value[0]]

  role   = each.value[1]
  member = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}

resource "google_project_iam_member" "project_additional_iam_roles" {
  for_each = local.additional_iam_roles

  project = var.project_ids_full[each.value[0]]

  role   = each.value[1]
  member = format("group:%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", each.value[0]), "%group%", var.group), var.domain != "" ? format("@%s", var.domain) : "")
}

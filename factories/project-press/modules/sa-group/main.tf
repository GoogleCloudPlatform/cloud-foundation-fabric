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
  sa_group_names = { for idx, env in var.environments : env => {
    group_key = format("%s%s", replace(replace(replace(var.group_format, "%project%", var.project_id), "%env%", env), "%number%", var.project_numbers[env]), var.domain != "" ? format("@%s", var.domain) : "")
    }
  }
  sa_members = [for idx, env in var.environments :
    { for member in var.service_accounts : "${env}-${md5(member)}" => {
      env    = env
      member = replace(replace(replace(member, "%project%", var.project_ids_full[env]), "%env%", env), "%number%", var.project_numbers[env])
    } }
  ]

  filtered_svpc_groups = { for env in var.environments : env => var.shared_vpc_groups[env] if var.shared_vpc_groups[env] != "" }
  shared_vpc_groups = { for env, svpc_group in local.filtered_svpc_groups : env => {
    group_id = var.all_groups[format("%s%s", svpc_group, var.domain != "" ? format("@%s", var.domain) : "")]
    }
  }
}

/**
 * Create service account group
 */
resource "google_cloud_identity_group" "sa_group" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : local.sa_group_names

  display_name = format("Service accounts: %s (%s)", var.project_id, upper(each.key))

  parent = format("customers/%s", var.customer_id)

  group_key {
    id = each.value.group_key
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "googleworkspace_group_settings" "sa-group-externals" {
  for_each = var.only_add_permissions ? {} : local.sa_group_names

  email                  = google_cloud_identity_group.sa_group[each.key].group_key[0].id
  allow_external_members = true
}

/**
 * Add service accounts to service account group
 */
resource "google_cloud_identity_group_membership" "sa-group-membership" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : merge(local.sa_members...)

  group = google_cloud_identity_group.sa_group[each.value.env].name

  member_key {
    id = lower(each.value.member)
  }

  roles {
    name = "MEMBER"
  }

  depends_on = [
    googleworkspace_group_settings.sa-group-externals
  ]
}

/**
 * Add service accounts group to Shared VPC group
 */
resource "google_cloud_identity_group_membership" "sa-group-svpc-membership" {
  provider = google-beta
  for_each = local.shared_vpc_groups

  group = each.value.group_id

  member_key {
    id = google_cloud_identity_group.sa_group[each.key].group_key[0].id
  }

  roles {
    name = "MEMBER"
  }
}

locals {
  api_service_accounts = [for idx, env in var.environments :
    [for api in var.activated_apis :
      { for sa in var.api_service_accounts[api] : format("%s-%s-%s", env, api, md5(sa)) =>
        {
          env             = env
          api             = api
          service_account = replace(replace(replace(sa, "%project%", var.project_ids_full[idx]), "%env%", env), "%number%", var.project_numbers[env])
        }
      }
      if lookup(var.api_service_accounts, api, null) != null
    ]
  ]
}

/**
 *  Add per API service accounts to service account groups
 */
resource "google_cloud_identity_group_membership" "per-api-service-account-membership" {
  provider = google-beta
  for_each = var.only_add_permissions ? {} : length(flatten(local.api_service_accounts)) > 0 ? merge(flatten(local.api_service_accounts)...) : {}

  group = google_cloud_identity_group.sa_group[each.value.env].name

  member_key {
    id = each.value.service_account
  }

  roles {
    name = "MEMBER"
  }

  depends_on = [
    googleworkspace_group_settings.sa-group-externals
  ]
}

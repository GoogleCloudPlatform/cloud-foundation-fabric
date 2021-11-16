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
  serverless_environments    = [for env in var.environments : env if var.serverless_groups[env] != ""]
  filtered_serverless_groups = { for env in local.serverless_environments : env => var.serverless_groups[env] if var.serverless_groups[env] != "" }

  serverless_sa_groups = var.only_add_project ? {} : { for env in local.serverless_environments : env => var.sa_groups[env] if var.sa_groups[env] != "" }
  serverless_sa_group_ids = var.only_add_project ? {} : { for env, serverless_group in local.filtered_serverless_groups : env =>
    var.all_groups[format("%s%s", serverless_group, var.domain != "" ? format("@%s", var.domain) : "")]
  }
}

resource "google_cloud_identity_group_membership" "serverless_sa_group_membership" {
  provider = google-beta
  for_each = length(local.serverless_sa_groups) > 0 ? local.serverless_sa_groups : {}

  group = local.serverless_sa_group_ids[each.key]

  member_key {
    id = lower(each.value[0].id)
  }

  roles {
    name = "MEMBER"
  }
}

locals {
  sa_members = [for idx, env in local.serverless_environments :
    { for member in var.serverless_service_accounts : "${env}-${md5(member)}" => {
      env    = env
      member = replace(replace(replace(member, "%project%", var.project_ids_full[env]), "%env%", env), "%number%", var.project_numbers[env])
    } }
  ]
}

resource "google_cloud_identity_group_membership" "serverless_sa_membership" {
  provider = google-beta
  for_each = length(local.sa_members) > 0 ? merge(local.sa_members...) : {}

  group = local.serverless_sa_group_ids[each.value.env]

  member_key {
    id = each.value.member
  }

  roles {
    name = "MEMBER"
  }
}

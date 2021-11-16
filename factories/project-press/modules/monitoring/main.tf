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
  sd_environments = compact([for env in var.environments : var.monitoring_projects[env] != "" ? env : ""])
}

resource "google_monitoring_monitored_project" "primary" {
  provider = google-beta
  for_each = toset(local.sd_environments)

  metrics_scope = var.monitoring_projects[each.value]
  name          = var.project_ids_full[each.value]
}

locals {
  monitoring_envs = [for env in var.environments : env if var.monitoring_groups[env] != ""]
  monitoring_groups = flatten([for env in local.monitoring_envs :
    { for g in var.project_groups[env] : format("%s-%s-%s", env, var.monitoring_groups[env], g[0].id) =>
      {
        group  = format("%s%s", var.monitoring_groups[env], var.domain != "" ? format("@%s", var.domain) : "")
        member = g[0].id
      }
    }
  ])
}

resource "google_cloud_identity_group_membership" "monitoring_group_membership" {
  provider = google-beta
  for_each = length(local.monitoring_groups[0]) > 0 ? local.monitoring_groups[0] : {}

  group = var.all_groups[each.value.group]

  member_key {
    id = lower(each.value.member)
  }

  roles {
    name = "MEMBER"
  }
}

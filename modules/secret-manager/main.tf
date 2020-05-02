/**
 * Copyright 2019 Google LLC
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
  # distinct is needed to make the expanding function argument work
  iam_pairs = flatten([
    for name, roles in var.iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  version_pairs = flatten([
    for name, versions in var.versions :
    [for version in versions : merge(version, { secret = name })]
  ])
  version_keypairs = {
    for pair in local.version_pairs :
    "${pair.secret}:${pair.name}" => pair
  }
}

resource "google_secret_manager_secret" "default" {
  provider  = google-beta
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key
  labels    = lookup(var.labels, each.key, null)

  dynamic replication {
    for_each = each.value == null ? [""] : []
    content {
      automatic = true
    }
  }

  dynamic replication {
    for_each = each.value == null ? [] : [each.value]
    iterator = locations
    content {
      user_managed {
        dynamic replicas {
          for_each = locations.value
          iterator = location
          content {
            location = location.value
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "default" {
  provider    = google-beta
  for_each    = local.version_keypairs
  secret      = google_secret_manager_secret.default[each.value.secret].id
  enabled     = each.value.enabled
  secret_data = each.value.data
}

resource "google_secret_manager_secret_iam_binding" "default" {
  provider  = google-beta
  for_each  = local.iam_keypairs
  role      = each.value.role
  secret_id = google_secret_manager_secret.default[each.value.name].id
  members = lookup(
    lookup(var.iam_members, each.value.name, {}), each.value.role, []
  )
}

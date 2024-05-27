/**
 * Copyright 2024 Google LLC
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

resource "google_apigee_environment_iam_binding" "authoritative" {
  for_each = merge(concat([for k1, v1 in var.environments : {
    for k2, v2 in v1.iam : "${k1}-${k2}" => {
      environment = k1
      role        = k2
      members     = v2
    }
  }])...)
  org_id  = local.org_id
  env_id  = google_apigee_environment.environments[each.value.environment].name
  role    = each.value.role
  members = each.value.members
}

resource "google_apigee_environment_iam_binding" "bindings" {
  for_each = merge(concat([for k1, v1 in var.environments : {
    for k2, v2 in coalesce(v1.iam_bindings, {}) : "${k1}-${k2}" => {
      environment = k1
      role        = v2.role
      members     = v2.members
    }
  }])...)
  org_id  = local.org_id
  env_id  = google_apigee_environment.environments[each.value.environment].name
  role    = each.value.role
  members = each.value.members
}

resource "google_apigee_environment_iam_member" "bindings" {
  for_each = merge(concat([for k1, v1 in var.environments : {
    for k2, v2 in coalesce(v1.iam_bindings_additive, {}) : "${k1}-${k2}" => {
      environment = k1
      role        = v2.role
      member      = v2.member
    }
  }])...)
  org_id = local.org_id
  env_id = google_apigee_environment.environments[each.value.environment].name
  role   = each.value.role
  member = each.value.member
}

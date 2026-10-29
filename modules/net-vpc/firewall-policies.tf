/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Network firewall policy associations.

locals {
  firewall_policy_associations = {
    for k, v in var.firewall_policy_associations : k => {
      name   = coalesce(v.name, "${var.name}-${k}")
      policy = v.policy
      region = lookup(local.ctx.locations, k, k)
    }
  }
}

resource "google_compute_network_firewall_policy_association" "default" {
  for_each = {
    for k, v in local.firewall_policy_associations : k => v if k == "global"
  }
  project           = local.project_id
  name              = each.value.name
  attachment_target = local.network.id
  firewall_policy   = each.value.policy
}

resource "google_compute_region_network_firewall_policy_association" "default" {
  for_each = {
    for k, v in local.firewall_policy_associations : k => v if k != "global"
  }
  project           = local.project_id
  region            = each.value.region
  name              = each.value.name
  attachment_target = local.network.id
  firewall_policy   = each.value.policy
}

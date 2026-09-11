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

locals {
  _tag_bindings = {
    for k, v in var.tag_bindings : k => lookup(local.ctx.tag_values, v, v)
  }
  location = local.use_hierarchical ? null : lookup(local.ctx.locations, var.region, var.region)
  _policy_numeric_id = one(concat(
    google_compute_region_network_firewall_policy.net_regional[*].region_network_firewall_policy_id,
    google_compute_network_firewall_policy.net_global[*].network_firewall_policy_id
  ))
  policy_parent = local.use_hierarchical ? null : (
    var.region == "global"
    ? "//compute.googleapis.com/projects/${var.parent_id}/global/firewallPolicies/${local._policy_numeric_id}"
    : "//compute.googleapis.com/projects/${var.parent_id}/regions/${var.region}/firewallPolicies/${local._policy_numeric_id}"
  )
}

resource "google_tags_location_tag_binding" "binding" {
  for_each  = !local.use_hierarchical ? var.tag_bindings : {}
  parent    = local.policy_parent
  location  = local.location
  tag_value = templatestring(local._tag_bindings[each.key], var.context.tag_vars)
}

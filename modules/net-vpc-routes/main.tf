/**
 * Copyright 2025 Google LLC
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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"

  # Network - already resolved in factory to full self-link, use directly
  # Factory resolves $vpc_ids: references to projects/PROJECT_ID/global/networks/NAME
  network_id   = lookup(local.ctx.vpc_ids, var.network_id, var.network_id)
  segments = split("/", local.network_id)
  project_id   = local.segments[1]
  network_name = local.segments[4]
}

resource "google_compute_route" "route" {
  count = var.route_create ? 1 : 0

  # Core route configuration
  project     = local.project_id
  name        = var.name
  network     = local.network_id
  description = var.description

  # Destination configuration
  dest_range = var.dest_range

  # Priority and tags
  priority = var.priority
  tags     = var.tags

  # Next hop configuration (only one can be specified)
  next_hop_gateway    = var.next_hop_gateway
  next_hop_instance   = var.next_hop_instance
  next_hop_instance_zone = var.next_hop_instance_zone
  next_hop_ip         = var.next_hop_ip
  next_hop_vpn_tunnel = var.next_hop_vpn_tunnel
  next_hop_ilb        = var.next_hop_ilb
}
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

  # Network - already resolved in factory to full self-link, use directly
  # Factory resolves $vpc_ids: references to projects/PROJECT_ID/global/networks/NAME
}

resource "google_compute_firewall" "rule" {
  count = var.rule_create ? 1 : 0

  # Core firewall configuration
  project     = local.project_id
  name        = var.name
  network     = local.network_id
  description = var.description

  # Direction and priority
  direction = var.direction
  priority  = var.priority
  disabled  = var.disabled

  # Source/destination configuration
  source_ranges              = var.source_ranges
  source_tags                = var.source_tags
  source_service_accounts    = var.source_service_accounts
  destination_ranges         = var.destination_ranges
  target_tags                = var.target_tags
  target_service_accounts    = var.target_service_accounts

  # Allow rules
  dynamic "allow" {
    for_each = length(var.deny) > 0 ? [] : var.allow
    content {
      protocol = allow.value.protocol
      ports    = try(allow.value.ports, null)
    }
  }

  # Deny rules
  dynamic "deny" {
    for_each = length(var.deny) > 0 ? var.deny : []
    content {
      protocol = deny.value.protocol
      ports    = try(deny.value.ports, null)
    }
  }

  # Logging configuration
  dynamic "log_config" {
    for_each = var.enable_logging != null ? [1] : []
    content {
      metadata = var.log_config.metadata
    }
  }
}
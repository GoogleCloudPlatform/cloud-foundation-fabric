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

  # Router - resolve router_id from context or use directly
  vpc_router_ids = lookup(local.ctx.vpc_router_ids, var.vpc_router_id, var.vpc_router_id)
  # Extract project_id and region from router ID format: projects/{project}/regions/{region}/routers/{router}
  router_segments = split("/", local.vpc_router_ids)
  project_id      = local.router_segments[1]
  region          = local.router_segments[3]
  router_name     = local.router_segments[5]
}

resource "google_compute_router_nat" "nat" {
  count = var.nat_create ? 1 : 0

  project = local.project_id
  name    = var.name
  router  = local.router_name
  region  = local.region

  # NAT IP allocation
  nat_ip_allocate_option = var.nat_ip_allocate_option
  nat_ips                = var.nat_ips
  auto_network_tier      = var.auto_network_tier

  # Source subnetwork configuration
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat

  # Subnetworks (when using LIST_OF_SUBNETWORKS)
  dynamic "subnetwork" {
    for_each = var.subnetworks
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = try(subnetwork.value.secondary_ip_range_names, null)
    }
  }

  # Connection timeouts
  icmp_idle_timeout_sec            = var.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec = var.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec  = var.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec        = var.tcp_time_wait_timeout_sec
  udp_idle_timeout_sec             = var.udp_idle_timeout_sec

  # Port allocation
  min_ports_per_vm                    = var.min_ports_per_vm
  max_ports_per_vm                    = var.max_ports_per_vm
  enable_dynamic_port_allocation      = var.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = var.enable_endpoint_independent_mapping

  # Logging
  dynamic "log_config" {
    for_each = var.log_config != null ? [var.log_config] : []
    content {
      enable = log_config.value.enable
      filter = log_config.value.filter
    }
  }

  # Drain NAT IPs
  drain_nat_ips = var.drain_nat_ips

  # NAT rules
  dynamic "rules" {
    for_each = var.rules
    content {
      rule_number = rules.value.rule_number
      description = try(rules.value.description, null)
      match       = rules.value.match

      dynamic "action" {
        for_each = try(rules.value.action, null) != null ? [rules.value.action] : []
        content {
          source_nat_active_ips    = try(action.value.source_nat_active_ips, null)
          source_nat_drain_ips     = try(action.value.source_nat_drain_ips, null)
          source_nat_active_ranges = try(action.value.source_nat_active_ranges, null)
          source_nat_drain_ranges  = try(action.value.source_nat_drain_ranges, null)
        }
      }
    }
  }

  # Type (PUBLIC or PRIVATE) - requires beta provider
  type = var.type
}

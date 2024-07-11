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

locals {
  router_name = (
    var.router_create
    ? try(google_compute_router.router[0].name, null)
    : var.router_name
  )
  subnet_config = (
    var.config_source_subnetworks.all != true
    ? "LIST_OF_SUBNETWORKS"
    : (
      var.config_source_subnetworks.primary_ranges_only == true
      ? "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
      : "ALL_SUBNETWORKS_ALL_IP_RANGES"
    )
  )
}

resource "google_compute_router" "router" {
  count   = var.router_create ? 1 : 0
  name    = var.router_name == null ? "${var.name}-nat" : var.router_name
  project = var.project_id
  region  = var.region
  network = var.router_network

  dynamic "bgp" {
    for_each = var.router_asn == null ? [] : [1]
    content {
      asn = var.router_asn
    }
  }
}

resource "google_compute_router_nat" "nat" {
  provider       = google-beta
  project        = var.project_id
  region         = var.region
  name           = var.name
  endpoint_types = var.endpoint_types
  type           = var.type
  router         = local.router_name
  nat_ips        = var.addresses
  nat_ip_allocate_option = (
    var.type == "PRIVATE"
    ? null
    : (
      length(var.addresses) > 0
      ? "MANUAL_ONLY"
      : "AUTO_ONLY"
    )
  )
  source_subnetwork_ip_ranges_to_nat = local.subnet_config
  icmp_idle_timeout_sec              = var.config_timeouts.icmp
  udp_idle_timeout_sec               = var.config_timeouts.udp
  tcp_established_idle_timeout_sec   = var.config_timeouts.tcp_established
  tcp_time_wait_timeout_sec          = var.config_timeouts.tcp_time_wait
  tcp_transitory_idle_timeout_sec    = var.config_timeouts.tcp_transitory
  enable_endpoint_independent_mapping = (
    var.config_port_allocation.enable_endpoint_independent_mapping
  )
  enable_dynamic_port_allocation = (
    var.config_port_allocation.enable_dynamic_port_allocation
  )
  min_ports_per_vm = (
    var.config_port_allocation.min_ports_per_vm
  )
  max_ports_per_vm = (
    var.config_port_allocation.max_ports_per_vm
  )

  log_config {
    enable = var.logging_filter == null ? false : true
    filter = var.logging_filter == null ? "ALL" : var.logging_filter
  }

  dynamic "subnetwork" {
    for_each = toset(
      local.subnet_config == "LIST_OF_SUBNETWORKS"
      ? var.config_source_subnetworks.subnetworks
      : []
    )
    content {
      name = subnetwork.value.self_link
      source_ip_ranges_to_nat = (
        subnetwork.value.all_ranges == true
        ? ["ALL_IP_RANGES"]
        : concat(
          (
            subnetwork.value.primary_range
            ? ["PRIMARY_IP_RANGE"]
            : []
          )
          ,
          (
            subnetwork.value.secondary_ranges == null
            ? []
            : ["LIST_OF_SECONDARY_IP_RANGES"]
          )
        )
      )
      secondary_ip_range_names = (
        subnetwork.value.all_ranges == true
        ? null
        : subnetwork.value.secondary_ranges
      )
    }
  }

  dynamic "rules" {
    for_each = { for i, r in var.rules : i => r }
    content {
      rule_number = rules.key
      description = rules.value.description
      match       = rules.value.match
      action {
        source_nat_active_ips    = rules.value.source_ips
        source_nat_active_ranges = rules.value.source_ranges
      }
    }
  }
}

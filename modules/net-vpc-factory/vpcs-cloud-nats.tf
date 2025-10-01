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
  _cloud_nats_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.cloud_nat_folder, "cloud-nats")}/*.yaml"
      ), []) :
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path = "${vpc_key}/${f}"
        vpc_key   = vpc_key
        nat_name  = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  _cloud_nats_data_raw = {
    for k, v in local._cloud_nats_data_files : k => merge(
      yamldecode(file("${local._vpc_path}/${v.file_path}")),
      {
        vpc_key  = v.vpc_key
        nat_name = v.nat_name
      }
    )
  }

  cloud_nat_inputs = {
    for k, v in local._cloud_nats_data_raw : k => merge(v, {
      # name - required
      name = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.name,
          try(v.name, null),
          local.data_defaults.defaults.cloud_nats.name
        ),
        v.nat_name
      )

      # router - required, supports $router_ids: context interpolation
      vpc_router_id = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.vpc_router_id,
          try(v.vpc_router_id, null),
          local.data_defaults.defaults.cloud_nats.vpc_router_id
        ),
        null
      )

      # nat_ip_allocate_option
      nat_ip_allocate_option = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.nat_ip_allocate_option,
          try(v.nat_ip_allocate_option, null),
          local.data_defaults.defaults.cloud_nats.nat_ip_allocate_option
        ),
        "AUTO_ONLY"
      )

      # nat_ips
      nat_ips = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.nat_ips,
          try(v.nat_ips, null),
          local.data_defaults.defaults.cloud_nats.nat_ips
        ),
        []
      )

      # auto_network_tier
      auto_network_tier = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.auto_network_tier,
          try(v.auto_network_tier, null),
          local.data_defaults.defaults.cloud_nats.auto_network_tier
        ),
        "PREMIUM"
      )

      # source_subnetwork_ip_ranges_to_nat
      source_subnetwork_ip_ranges_to_nat = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.source_subnetwork_ip_ranges_to_nat,
          try(v.source_subnetwork_ip_ranges_to_nat, null),
          local.data_defaults.defaults.cloud_nats.source_subnetwork_ip_ranges_to_nat
        ),
        "ALL_SUBNETWORKS_ALL_IP_RANGES"
      )

      # subnetworks
      subnetworks = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.subnetworks,
          try(v.subnetworks, null),
          local.data_defaults.defaults.cloud_nats.subnetworks
        ),
        []
      )

      # icmp_idle_timeout_sec
      icmp_idle_timeout_sec = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.icmp_idle_timeout_sec,
          try(v.icmp_idle_timeout_sec, null),
          local.data_defaults.defaults.cloud_nats.icmp_idle_timeout_sec
        ),
        30
      )

      # tcp_established_idle_timeout_sec
      tcp_established_idle_timeout_sec = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.tcp_established_idle_timeout_sec,
          try(v.tcp_established_idle_timeout_sec, null),
          local.data_defaults.defaults.cloud_nats.tcp_established_idle_timeout_sec
        ),
        1200
      )

      # tcp_transitory_idle_timeout_sec
      tcp_transitory_idle_timeout_sec = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.tcp_transitory_idle_timeout_sec,
          try(v.tcp_transitory_idle_timeout_sec, null),
          local.data_defaults.defaults.cloud_nats.tcp_transitory_idle_timeout_sec
        ),
        30
      )

      # tcp_time_wait_timeout_sec
      tcp_time_wait_timeout_sec = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.tcp_time_wait_timeout_sec,
          try(v.tcp_time_wait_timeout_sec, null),
          local.data_defaults.defaults.cloud_nats.tcp_time_wait_timeout_sec
        ),
        120
      )

      # udp_idle_timeout_sec
      udp_idle_timeout_sec = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.udp_idle_timeout_sec,
          try(v.udp_idle_timeout_sec, null),
          local.data_defaults.defaults.cloud_nats.udp_idle_timeout_sec
        ),
        30
      )

      # min_ports_per_vm
      min_ports_per_vm = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.min_ports_per_vm,
          try(v.min_ports_per_vm, null),
          local.data_defaults.defaults.cloud_nats.min_ports_per_vm
        ),
        64
      )

      # max_ports_per_vm
      max_ports_per_vm = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.max_ports_per_vm,
          try(v.max_ports_per_vm, null),
          local.data_defaults.defaults.cloud_nats.max_ports_per_vm
        ),
        null
      )

      # enable_dynamic_port_allocation
      enable_dynamic_port_allocation = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.enable_dynamic_port_allocation,
          try(v.enable_dynamic_port_allocation, null),
          local.data_defaults.defaults.cloud_nats.enable_dynamic_port_allocation
        ),
        false
      )

      # enable_endpoint_independent_mapping
      enable_endpoint_independent_mapping = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.enable_endpoint_independent_mapping,
          try(v.enable_endpoint_independent_mapping, null),
          local.data_defaults.defaults.cloud_nats.enable_endpoint_independent_mapping
        ),
        true
      )

      # log_config
      log_config = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.log_config,
          try(v.log_config, null),
          local.data_defaults.defaults.cloud_nats.log_config
        ),
        null
      )

      # drain_nat_ips
      drain_nat_ips = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.drain_nat_ips,
          try(v.drain_nat_ips, null),
          local.data_defaults.defaults.cloud_nats.drain_nat_ips
        ),
        []
      )

      # rules
      rules = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.rules,
          try(v.rules, null),
          local.data_defaults.defaults.cloud_nats.rules
        ),
        []
      )

      # type
      type = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.type,
          try(v.type, null),
          local.data_defaults.defaults.cloud_nats.type
        ),
        "PUBLIC"
      )

      # nat_create
      nat_create = try(
        coalesce(
          local.data_defaults.overrides.cloud_nats.nat_create,
          try(v.nat_create, null),
          local.data_defaults.defaults.cloud_nats.nat_create
        ),
        true
      )
    })
  }
}

module "cloud_nats" {
  source   = "../net-vpc-nat"
  for_each = local.cloud_nat_inputs

  context = merge(local.ctx, {
    vpc_ids    = merge(local.ctx.vpc_ids, local.vpc_ids)
    vpc_router_ids = merge(local.ctx.vpc_router_ids, local.vpc_router_ids)
  })

  # Core NAT configuration
  name       = each.value.name
  vpc_router_id     = each.value.vpc_router_id
  nat_create = each.value.nat_create

  # NAT IP configuration
  nat_ip_allocate_option = each.value.nat_ip_allocate_option
  nat_ips                = each.value.nat_ips
  auto_network_tier      = each.value.auto_network_tier

  # Subnetwork configuration
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat
  subnetworks                        = each.value.subnetworks

  # Connection timeouts
  icmp_idle_timeout_sec            = each.value.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec = each.value.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec  = each.value.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec        = each.value.tcp_time_wait_timeout_sec
  udp_idle_timeout_sec             = each.value.udp_idle_timeout_sec

  # Port allocation
  min_ports_per_vm                    = each.value.min_ports_per_vm
  max_ports_per_vm                    = each.value.max_ports_per_vm
  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping

  # Logging
  log_config = each.value.log_config

  # Drain and rules
  drain_nat_ips = each.value.drain_nat_ips
  rules         = each.value.rules

  # Type
  type = each.value.type

  depends_on = [ module.vpcs ]
}

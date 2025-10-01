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
  _routes_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.routes_folder, "routes")}/*.yaml"
      ), []) :
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path   = "${vpc_key}/${f}"
        vpc_key     = vpc_key
        environment = try(vpc_config.environment, split("/", vpc_key)[length(split("/", vpc_key)) - 1])
        route_name  = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  _routes_data_raw = {
    for k, v in local._routes_data_files : k => merge(
      yamldecode(file("${local._vpc_path}/${v.file_path}")),
      {
        vpc_key     = v.vpc_key
        environment = v.environment
        route_name  = v.route_name
      }
    )
  }

  route_inputs = {
    for k, v in local._routes_data_raw : k => merge(v, {
      # name - required
      name = try(
        coalesce(
          local.data_defaults.overrides.routes.name,
          try(v.name, null),
          local.data_defaults.defaults.routes.name
        ),
        v.route_name
      )

      # network_id - resolve $vpc_ids: references
      network_id = try(
        coalesce(
          local.data_defaults.overrides.routes.network_id,
          v.network_id,
          local.data_defaults.defaults.routes.network_id
        ),
        null
      )

      # description
      description = try(
        coalesce(
          local.data_defaults.overrides.routes.description,
          try(v.description, null),
          local.data_defaults.defaults.routes.description
        ),
        null
      )

      # dest_range - required
      dest_range = try(
        coalesce(
          local.data_defaults.overrides.routes.dest_range,
          try(v.dest_range, null),
          local.data_defaults.defaults.routes.dest_range
        ),
        null
      )

      # priority
      priority = try(
        coalesce(
          local.data_defaults.overrides.routes.priority,
          try(v.priority, null),
          local.data_defaults.defaults.routes.priority
        ),
        1000
      )

      # tags
      tags = try(
        coalesce(
          local.data_defaults.overrides.routes.tags,
          try(v.tags, null),
          local.data_defaults.defaults.routes.tags
        ),
        null
      )

      # next_hop_gateway
      next_hop_gateway = try(
        coalesce(
          local.data_defaults.overrides.routes.next_hop_gateway,
          try(v.next_hop_gateway, null),
          local.data_defaults.defaults.routes.next_hop_gateway
        ),
        null
      )

      # next_hop_instance
      next_hop_instance = try(
        coalesce(
          local.data_defaults.overrides.routes.next_hop_instance,
          try(v.next_hop_instance, null),
          local.data_defaults.defaults.routes.next_hop_instance
        ),
        null
      )

      # next_hop_ip
      next_hop_ip = try(
        coalesce(
          local.data_defaults.overrides.routes.next_hop_ip,
          try(v.next_hop_ip, null),
          local.data_defaults.defaults.routes.next_hop_ip
        ),
        null
      )

      # next_hop_vpn_tunnel
      next_hop_vpn_tunnel = try(
        coalesce(
          local.data_defaults.overrides.routes.next_hop_vpn_tunnel,
          try(v.next_hop_vpn_tunnel, null),
          local.data_defaults.defaults.routes.next_hop_vpn_tunnel
        ),
        null
      )

      # next_hop_ilb
      next_hop_ilb = try(
        coalesce(
          local.data_defaults.overrides.routes.next_hop_ilb,
          try(v.next_hop_ilb, null),
          local.data_defaults.defaults.routes.next_hop_ilb
        ),
        null
      )

      # route_create
      route_create = try(
        coalesce(
          local.data_defaults.overrides.routes.route_create,
          try(v.route_create, null),
          local.data_defaults.defaults.routes.route_create
        ),
        true
      )
    })
  }
}

module "routes" {
  source   = "../net-vpc-routes"
  for_each = local.route_inputs

  context = merge(local.ctx, {
    vpc_ids = merge(local.ctx.vpc_ids, local.vpc_ids)
  })

  # Core route configuration
  name        = each.value.name
  network_id  = each.value.network_id
  description = each.value.description

  # Destination
  dest_range = each.value.dest_range

  # Priority and tags
  priority = each.value.priority
  tags     = each.value.tags

  # Next hop configuration
  next_hop_gateway    = each.value.next_hop_gateway
  next_hop_instance   = each.value.next_hop_instance
  next_hop_ip         = each.value.next_hop_ip
  next_hop_vpn_tunnel = each.value.next_hop_vpn_tunnel
  next_hop_ilb        = each.value.next_hop_ilb

  # Control
  route_create = each.value.route_create

  depends_on = [ module.vpcs ]
  
}
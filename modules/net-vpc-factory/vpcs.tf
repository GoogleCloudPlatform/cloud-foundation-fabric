/**
 * Copyright 2022 Google LLC
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
  _vpc_path = try(
    pathexpand(var.factories_config.vpcs), null
  )

  _vpc_raw = {
    for f in try(fileset(local._vpc_path, "**/*.yaml"), []) :
    dirname(f) => yamldecode(file("${local._vpc_path}/${f}"))
    if endswith(f, ".config.yaml")
  }


  vpc_router_ids = merge([
    for vpc_key, vpc in module.vpcs : {
      for router_key, router in try(vpc.routers, {}) :
        "${vpc_key}/${router_key}" => router.id
    }
  ]...)

  vpc_ids = {
    for k, v in module.vpcs : k => v.id
  }

  # Process VPC configurations with context interpolation from _vpc_raw
  _vpcs_inputs = local._vpc_raw
  vpc_inputs = {
    # Semantics of the merges are:
    #   - if data_overrides.vpcs.<field> is not null, use this value
    #   - if  _vpcs_inputs.<field> is not null, use this value
    #   - use data_default.vpcs value, which if not set, will provide "empty" type
    # This logic is easily implemented using coalesce, even on maps and list and allows to
    # set data_overrides.vpcs.<field> to "", [] or {} to ensure, that empty value is always passed, or do
    # the same in _vpcs_input to prevent falling back to default value
    for k, v in local._vpcs_inputs : k => merge(v, {
      project_id = try(coalesce( # type: string
        local.data_defaults.overrides.vpcs.project_id,
        try(v.project_id, null),
        local.data_defaults.defaults.vpcs.project_id
      ), null)
      network_name = try(coalesce( # type: string
        local.data_defaults.overrides.vpcs.network_name,
        try(v.network_name, null),
        local.data_defaults.defaults.vpcs.network_name
      ), null)
      description = try(coalesce( # type: string
        local.data_defaults.overrides.vpcs.description,
        try(v.description, null),
        local.data_defaults.defaults.vpcs.description
      ), null)
      routing_mode = try(coalesce( # type: string
        local.data_defaults.overrides.vpcs.routing_mode,
        try(v.routing_mode, null),
        local.data_defaults.defaults.vpcs.routing_mode
      ), null)
      auto_create_subnetworks = try(coalesce( # type: bool
        local.data_defaults.overrides.vpcs.auto_create_subnetworks,
        try(v.auto_create_subnetworks, null),
        local.data_defaults.defaults.vpcs.auto_create_subnetworks
      ), null)
      delete_default_routes_on_create = try(coalesce( # type: bool
        local.data_defaults.overrides.vpcs.delete_default_routes_on_create,
        try(v.delete_default_routes_on_create, null),
        local.data_defaults.defaults.vpcs.delete_default_routes_on_create
      ), null)
      mtu = try(coalesce( # type: number
        local.data_defaults.overrides.vpcs.mtu,
        try(v.mtu, null),
        local.data_defaults.defaults.vpcs.mtu
      ), null)
      dns_policy = try(coalesce( # type: object
        local.data_defaults.overrides.vpcs.dns_policy,
        try(v.dns_policy, null),
        local.data_defaults.defaults.vpcs.dns_policy
      ), null)
      peering_config = try(coalesce( # type: object
        local.data_defaults.overrides.vpcs.peering_config,
        try(v.peering_config, null),
        local.data_defaults.defaults.vpcs.peering_config
      ), null)
      network_attachments = try(coalesce( # type: map
        local.data_defaults.overrides.vpcs.network_attachments,
        try(v.network_attachments, null),
        local.data_defaults.defaults.vpcs.network_attachments
      ),[])
      routers = try(coalesce( # type: map
        local.data_defaults.overrides.vpcs.routers,
        try(v.routers, null),
        local.data_defaults.defaults.vpcs.routers
      ), {})
      vpc_reuse = try(coalesce( # type: object
        local.data_defaults.overrides.vpcs.vpc_reuse,
        try(v.vpc_reuse, null),
        local.data_defaults.defaults.vpcs.vpc_reuse
      ), null)
      tag_bindings = try(coalesce( # type: object
        local.data_defaults.overrides.vpcs.tag_bindings,
        try(v.tag_bindings, null),
        local.data_defaults.defaults.vpcs.tag_bindings
      ), {})
    })
  }
}

# Create VPC networks using net-vpc module
module "vpcs" {
  source = "../net-vpc"

  for_each = local.vpc_inputs

  # Core identification
  project_id = each.value.project_id
  name       = each.value.network_name

  # VPC configuration with defaults
  description                     = each.value.description
  routing_mode                    = each.value.routing_mode
  auto_create_subnetworks         = each.value.auto_create_subnetworks
  delete_default_routes_on_create = each.value.delete_default_routes_on_create
  mtu                             = each.value.mtu
  tag_bindings                    = each.value.tag_bindings  

  # Cloud Routers
  routers = each.value.routers

  context = local.ctx
}


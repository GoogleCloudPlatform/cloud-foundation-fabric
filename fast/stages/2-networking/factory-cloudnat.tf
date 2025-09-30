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

# tfdoc:file:description Cloud NAT factory.

locals {

  nat_configs = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : [
      for nat_key, nat_config in try(vpc_config.nat_config, {}) : {
        "${vpc_key}/${nat_key}" = merge(nat_config, {
          name                      = replace("${vpc_key}/${nat_key}", "/", "-")
          project_id                = vpc_config.project_id
          addresses                 = try(nat_config.addresses, [])
          config_port_allocation    = try(nat_config.config_port_allocation, {})
          config_source_subnetworks = try(nat_config.config_source_subnetworks, {})
          config_timeouts           = try(nat_config.config_timeouts, {})
          endpoint_types            = try(nat_config.endpoint_types, null)
          logging_filter            = try(nat_config.logging_filter, null)
          router_asn                = try(nat_config.router_asn, null)
          router_create             = try(nat_config.router_create, true)
          router_network            = module.vpcs[vpc_key].self_link
          rules                     = try(nat_config.rules, [])
          type                      = try(nat_config.type, "PUBLIC")
        })
      }
    ]
  ])...)
}

#TODO(SR): implement passing existing router
module "nat" {
  source                    = "../../../modules/net-cloudnat"
  for_each                  = local.nat_configs
  project_id                = each.value.project_id
  name                      = each.value.name
  addresses                 = each.value.addresses
  config_port_allocation    = each.value.config_port_allocation
  config_source_subnetworks = each.value.config_source_subnetworks
  config_timeouts           = each.value.config_timeouts
  endpoint_types            = each.value.endpoint_types
  logging_filter            = each.value.logging_filter
  region                    = each.value.region
  router_asn                = each.value.router_asn
  router_create             = each.value.router_create
  router_network            = each.value.router_network
  rules                     = each.value.rules
  type                      = each.value.type
  context = merge(local.ctx, {
    project_ids    = merge(local.ctx.project_ids, module.factory.project_ids)
    vpc_self_links = local.ctx_vpcs.self_links
    locations      = local.ctx.locations
  })
}

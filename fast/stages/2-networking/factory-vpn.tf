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

# tfdoc:file:description VPN factory.

locals {
  routers = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : [
      for router_key, router_config in try(vpc_config.routers, {}) : {
        "${vpc_key}/${router_key}" = merge(router_config, {
          project_id        = module.vpc[vpc_key].project_id
          vpc_self_link     = module.vpc[vpc_key].self_link
          custom_advertise  = try(router_config.custom_advertise, {})
          advertise_mode    = try(router_config.custom_advertise != null, false) ? "CUSTOM" : "DEFAULT"
          advertised_groups = try(router_config.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
        })
      }
    ]
  ])...)

  _vpc_path_to_key_map = {
    for k, v in local.vpcs : v.factory_basepath => k
  }
  _vpn_files = fileset(var.factories_config.vpcs, "**/vpns/*.yaml")
  _vpns_preprocess = [
    for f in local._vpn_files :
    merge(
      yamldecode(file("${var.factories_config.vpcs}/${f}")),
      { vpc_key = local._vpc_path_to_key_map["${var.factories_config.vpcs}/${dirname(dirname(f))}"] }
    )
  ]
  vpns = {
    for vpn_config in local._vpns_preprocess : "${vpn_config.vpc_key}/${vpn_config.name}" => merge(vpn_config, {
      project_id = module.vpc[vpn_config.vpc_key].project_id
      vpc_name   = module.vpc[vpn_config.vpc_key].name
      router_config = merge(vpn_config.router_config,
        try(vpn_config.router_config.create, false) == false && can(vpn_config.router_config.name) ? {
          name = try(google_compute_router.vpn[vpn_config.router_config.name].name, vpn_config.router_config.name)
        } : {}
      )
    })
  }
}

resource "google_compute_router" "vpn" {
  for_each = local.routers
  name     = split(":", replace(each.key, "/", "-"))[1] #TODO: ugh
  project  = lookup(local.context, each.value.project_id, each.value.project_id)
  region   = each.value.region
  network  = each.value.vpc_self_link
  bgp {
    advertise_mode    = each.value.advertise_mode
    advertised_groups = each.value.advertised_groups
    dynamic "advertised_ip_ranges" {
      for_each = try(each.value.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = try(each.value.keepalive, null)
    asn                = each.value.asn
  }
}

resource "google_compute_ha_vpn_gateway" "default" {
  for_each   = local.vpns
  project    = lookup(local.context, each.value.project_id, each.value.project_id)
  region     = each.value.region
  name       = split(":", replace(each.key, "/", "-"))[1] #TODO: ugh
  network    = each.value.vpc_name
  stack_type = try(each.value.stack_type, null)
  depends_on = [module.vpc]
}

module "vpn-ha" {
  source             = "../../../modules/net-vpn-ha"
  for_each           = local.vpns
  project_id         = each.value.project_id
  name               = split(":", replace(each.key, "/", "-"))[1] #TODO: ugh
  network            = each.value.vpc_name
  region             = each.value.region
  router_config      = each.value.router_config
  tunnels            = each.value.tunnels
  vpn_gateway        = google_compute_ha_vpn_gateway.default[each.key].id
  vpn_gateway_create = null
  peer_gateways = {
    for k, gw in each.value.peer_gateways : k => {
      for gw_type, value in gw : gw_type => (
        gw_type == "gcp" ? try(google_compute_ha_vpn_gateway.default[value].id, value) : value
      )
    }
  }
}

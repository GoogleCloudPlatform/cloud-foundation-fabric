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
    for factory_key, factory_config in local.network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for router_key, router_config in try(vpc_config.routers, {}) : {
          "${factory_key}/${vpc_key}/${router_key}" = merge(router_config, {
            vpc_self_link     = module.vpc["${factory_key}/${vpc_key}"].self_link
            project_id        = module.projects[factory_key].id
            custom_advertise  = try(router_config.custom_advertise, {})
            advertise_mode    = try(router_config.custom_advertise != null, false) ? "CUSTOM" : "DEFAULT"
            advertised_groups = try(router_config.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
            keepalive         = try(router_config.keepalive, null)
            asn               = try(router_config.asn, null)
          })
        }
      ]
    ]
  ])...)

  vpns = merge(flatten([
    for factory_key, factory_config in local.network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for k, v in try(vpc_config.vpn_config, {}) : {
          "${factory_key}/${vpc_key}/${k}" = merge(v, {
            vpc_name   = module.vpc["${factory_key}/${vpc_key}"].name
            vpn_name   = replace("${factory_key}/${vpc_key}/${k}", "/", "-")
            project_id = module.projects[factory_key].id
            },
            {
              router_config = merge(v.router_config,
                try(v.router_config.create, false) == false && can(v.router_config.name) ? {
                  name = try(google_compute_router.default[v.router_config.name].name, v.router_config.name)
                } : {}
              )
            }
          )
        }
      ]
    ]
  ])...)
}

resource "google_compute_router" "default" {
  for_each = local.routers
  name     = replace(each.key, "/", "-")
  project  = each.value.project_id
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
    keepalive_interval = each.value.keepalive
    asn                = each.value.asn
  }
}

resource "google_compute_ha_vpn_gateway" "default" {
  for_each   = local.vpns
  project    = each.value.project_id
  region     = each.value.region
  name       = replace(each.key, "/", "-")
  network    = each.value.vpc_name
  stack_type = try(each.value.stack_type, null)
  depends_on = [module.vpc]
}

module "vpn-ha" {
  source             = "../net-vpn-ha"
  for_each           = local.vpns
  project_id         = each.value.project_id
  name               = replace(each.key, "/", "-")
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

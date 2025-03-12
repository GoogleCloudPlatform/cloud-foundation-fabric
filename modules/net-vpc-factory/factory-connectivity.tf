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
  peerings = merge(flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for k, v in try(vpc_config.peering_config, {}) : {
          "${factory_key}/${vpc_key}/${k}" = {
            project                             = factory_key
            name                                = replace("${vpc_key}/${k}", "/", "-")
            local_network                       = module.vpcs["${factory_key}/${vpc_key}"].self_link
            peer_network                        = module.vpcs[v.peer_network].self_link
            export_custom_routes                = try(v.routes_config.export, true)
            import_custom_routes                = try(v.routes_config.import, true)
            export_subnet_routes_with_public_ip = try(v.routes_config.public_export, null)
            import_subnet_routes_with_public_ip = try(v.routes_config.public_import, null)
          }
        }
      ]
    ]
  ])...)

  routers = merge(flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for router_key, router_config in try(vpc_config.routers, {}) : {
          "${factory_key}/${vpc_key}/${router_key}" = merge(router_config, {
            vpc_self_link     = module.vpcs["${factory_key}/${vpc_key}"].self_link
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
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for k, v in try(vpc_config.vpn_config, {}) : {
          "${factory_key}/${vpc_key}/${k}" = merge(v, {
            vpc_name   = module.vpcs["${factory_key}/${vpc_key}"].name
            vpn_name   = replace("${factory_key}/${vpc_key}/${k}", "/", "-")
            project_id = module.projects[factory_key].id
            },
            {
              router_config = merge(v.router_config,
                try(v.router_config.create, false) == false ? {
                  name = try(google_compute_router.router[v.router_config.name].name, v.router_config.name)
              } : {})
            }
          )
        }
      ]
    ]
  ])...)
}

#TODO(sruffilli): implement stack_type
resource "google_compute_network_peering" "local_network_peering" {
  for_each                            = local.peerings
  name                                = each.value.name
  network                             = each.value.local_network
  peer_network                        = each.value.peer_network
  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
}


resource "google_compute_router" "router" {
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

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  for_each   = local.vpns
  project    = each.value.project_id
  region     = each.value.region
  name       = replace(each.key, "/", "-")
  network    = each.value.vpc_name
  stack_type = "IPV4_ONLY"
  depends_on = [module.vpcs]
}

#TODO(sruffilli) How do we manage reusing the same CR for multiple VPNs? It smells like a hard-ish nut to crack.
module "vpn-ha" {
  source             = "../net-vpn-ha"
  for_each           = local.vpns
  project_id         = each.value.project_id
  name               = replace(each.key, "/", "-")
  network            = each.value.vpc_name
  region             = each.value.region
  router_config      = each.value.router_config
  tunnels            = each.value.tunnels
  vpn_gateway        = google_compute_ha_vpn_gateway.ha_gateway[each.key].id
  vpn_gateway_create = null
  peer_gateways = {
    for k, gw in each.value.peer_gateways : k => {
      for gw_type, value in gw : gw_type => (
        #TODO(sruffilli): create a lookup table instead, that only does this replacement if value exists, 
        #to allow passing an arbitrary gateway id
        gw_type == "gcp" ? google_compute_ha_vpn_gateway.ha_gateway[value].id : value
      )
    }
  }
}

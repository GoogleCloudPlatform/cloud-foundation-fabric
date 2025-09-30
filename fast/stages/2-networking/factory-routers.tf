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
  ctx_routers = {
    ids   = { for k, v in google_compute_router.default : k => v.id }
    names = { for k, v in google_compute_router.default : k => v.name }
  }

  router_configs = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : [
      for router_key, router_config in try(vpc_config.routers, {}) : {
        "${vpc_key}/${router_key}" = merge(router_config, {
          name              = replace("${vpc_key}/${router_key}", "/", "-")
          vpc_self_link     = vpc_key
          project_id        = vpc_config.project_id
          custom_advertise  = try(router_config.custom_advertise, {})
          advertise_mode    = try(router_config.custom_advertise != null, false) ? "CUSTOM" : "DEFAULT"
          advertised_groups = try(router_config.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
          keepalive         = try(router_config.keepalive, null)
          asn               = try(router_config.asn, null)
        })
      }
    ]
  ])...)
}

resource "google_compute_router" "default" {
  for_each = local.router_configs
  name     = replace(each.key, "/", "-")
  project  = lookup(merge(local.ctx.project_ids, module.factory.project_ids), replace(each.value.project_id, "$project_ids:", ""), each.value.project_id)
  region   = lookup(local.ctx.locations, each.value.region, each.value.region)
  network  = lookup(local.ctx_vpcs.self_links, each.value.vpc_self_link, each.value.vpc_self_link)
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

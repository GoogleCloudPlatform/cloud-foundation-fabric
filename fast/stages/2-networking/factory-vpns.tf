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

# tfdoc:file:description VPNs factory.

locals {
  _vpns_files = try(
    fileset(local._vpcs_path, "**/vpns/*.yaml"),
    []
  )
  _vpns_preprocess = [
    for f in local._vpns_files : merge(
      yamldecode(file("${coalesce(local._vpcs_path, "-")}/${f}")),
      {
        factory_basepath = dirname(dirname(f))
      }
    )
  ]
  ctx_gateways = { for k, v in google_compute_ha_vpn_gateway.default : k => v.id }
  vpns = {
    for v in local._vpns_preprocess : "${v.factory_basepath}/${v.name}" => merge(v, {
      vpc_name = v.factory_basepath
      # TODO: discuss - this is pushing context at any cost, as project could be easily resolved
      # as module.vpcs[v.factory_basepath].project_id
      project_id    = local.vpcs[v.factory_basepath].project_id
      router_config = try(v.router_config, {})
      region        = try(v.region, local.defaults.vpcs.region)
      peer_gateways = try(v.peer_gateways, {})
      tunnels       = try(v.tunnels, {})
    })
  }
}

resource "google_compute_ha_vpn_gateway" "default" {
  for_each = local.vpns
  project = lookup(
    merge(local.ctx.project_ids, module.projects.project_ids),
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  region = lookup(
    local.ctx.locations,
    replace(each.value.region, "$locations:", ""),
    each.value.region
  )
  network = lookup(
    local.ctx_vpcs.names, each.value.vpc_name, each.value.vpc_name
  )
  name       = replace(each.key, "/", "-")
  stack_type = try(each.value.stack_type, null)
  depends_on = [module.vpcs]
}

module "vpn-ha" {
  source             = "../../../modules/net-vpn-ha"
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
        gw_type == "gcp"
        ? try(google_compute_ha_vpn_gateway.default[value].id, value)
        : value
      )
    }
  }
  context = {
    locations    = local.ctx.locations
    network      = local.ctx_vpcs.names
    project_ids  = local.ctx_projects.project_ids
    routers      = local.ctx_routers.names
    vpn_gateways = local.ctx_gateways
  }
}

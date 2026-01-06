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

# tfdoc:file:description NCC Hubs and Groups factory

locals {
  _ncc_path  = try(pathexpand(var.factories_config.ncc-hubs), null)
  _ncc_files = try(fileset(local._ncc_path, "**/*.yaml"), [])
  _ncc_preprocess = [
    for f in local._ncc_files : yamldecode(
      file("${coalesce(local._ncc_path, "-")}/${f}")
    )
  ]
  # Since NCC groups depend on NCC hubs, two different lookup maps avoid circular dependencies.
  ctx_ncc_groups = {
    for k, v in google_network_connectivity_group.default : k => v.id
  }
  ctx_ncc_hubs = {
    for k, v in google_network_connectivity_hub.default : k => v.id
  }
  ncc_hubs = {
    for k, v in local._ncc_preprocess : v.name => {
      project_id      = v.project_id
      description     = try(v.description, "Terraform-managed")
      export_psc      = try(v.export_psc, true)
      preset_topology = try(v.preset_topology, "MESH")
    }
  }
  ncc_groups = merge(flatten([
    for k, v in local._ncc_preprocess : {
      for gk, gv in try(v.groups, {}) : "${v.name}/${gk}" =>
      {
        name        = gk
        project_id  = v.project_id
        hub         = v.name
        description = try(gv.description, "Terraform-managed")
        labels      = try(gv.labels, {})
        auto_accept = try(gv.auto_accept, [])
      }
    }
  ])...)
  ncc_vpc_spokes = {
    for vpc_key, vpc_config in local.vpcs :
    "${vpc_key}/${replace(vpc_config.ncc_config.hub, "$ncc_hubs:", "")}" => merge(
      vpc_config.ncc_config,
      {
        project_id            = vpc_config.project_id
        vpc_self_link         = vpc_key
        labels                = try(vpc_config.ncc_config.labels, {})
        hub                   = vpc_config.ncc_config.hub
        description           = try(vpc_config.ncc_config.description, "Terraform-managed")
        exclude_export_ranges = try(vpc_config.ncc_config.exclude_export_ranges, null)
        include_export_ranges = try(vpc_config.ncc_config.include_export_ranges, null)
        group                 = try(vpc_config.ncc_config.group, null)
      }
    ) if try(vpc_config.ncc_config != null, false)
  }
  ncc_vpn_spokes = {
    for vpn_key, vpn_config in local.vpns :
    "${vpn_key}/${replace(vpn_config.ncc_spoke_config.hub, "$ncc_hubs:", "")}" => merge(
      vpn_config.ncc_spoke_config,
      {
        name             = replace("${vpn_key}/${vpn_config.ncc_spoke_config.hub}", "$ncc_hubs:", "") # TODO: eww
        project_id       = vpn_config.project_id
        hub              = vpn_config.ncc_spoke_config.hub
        group            = try(vpn_config.ncc_spoke_config.group, null)
        location         = vpn_config.region
        description      = lookup(vpn_config.ncc_spoke_config, "description", "Terraform-managed.")
        labels           = lookup(vpn_config.ncc_spoke_config, "labels", {})
        tunnel_self_link = [for t, _ in vpn_config.tunnels : module.vpn-ha[vpn_key].tunnel_self_links[t]]
      }
    ) if try(vpn_config.ncc_spoke_config != null, false)
  }
}

resource "google_network_connectivity_hub" "default" {
  for_each = local.ncc_hubs
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name            = each.key
  description     = each.value.description
  export_psc      = each.value.export_psc
  preset_topology = each.value.preset_topology
}

resource "google_network_connectivity_group" "default" {
  for_each = local.ncc_groups
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name = each.value.name
  hub = lookup(
    local.ctx_ncc_hubs, replace(each.value.hub, "$ncc_hubs:", ""), each.value.hub
  )
  labels      = each.value.labels
  description = each.value.description
  dynamic "auto_accept" {
    for_each = try(each.value.auto_accept != null, false) ? [""] : []
    content {
      auto_accept_projects = [
        for project_key in try(each.value.auto_accept, []) : lookup(
          local.ctx_projects.project_ids,
          replace(project_key, "$project_ids:", ""),
          project_key
        )
      ]
    }
  }
  depends_on = [google_network_connectivity_hub.default]
}

resource "google_network_connectivity_spoke" "vpcs" {
  for_each = local.ncc_vpc_spokes
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name        = replace(each.key, "/", "-")
  location    = "global"
  description = each.value.description
  labels      = each.value.labels
  hub = lookup(
    local.ctx_ncc_hubs,
    replace(each.value.hub, "$ncc_hubs:", ""),
    each.value.hub
  )
  linked_vpc_network {
    uri = lookup(
      local.ctx_vpcs.self_links,
      each.value.vpc_self_link,
      each.value.vpc_self_link
    )
    exclude_export_ranges = each.value.exclude_export_ranges
    include_export_ranges = each.value.include_export_ranges
  }
  group = each.value.group == null ? null : lookup(
    local.ctx_ncc_groups,
    replace(each.value.group, "$ncc_groups:", ""),
    each.value.group
  )
  depends_on = [google_network_connectivity_hub.default]
}

resource "google_network_connectivity_spoke" "tunnels" {
  for_each = local.ncc_vpn_spokes
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name = replace(each.key, "/", "-")
  location = lookup(
    local.ctx.locations,
    replace(each.value.location, "$locations:", ""),
    each.value.location
  )
  description = each.value.description
  labels      = each.value.labels
  hub = lookup(
    local.ctx_ncc_hubs,
    replace(each.value.hub, "$ncc_hubs:", ""),
    each.value.hub
  )
  group = each.value.group == null ? null : lookup(
    local.ctx_ncc_groups,
    replace(each.value.group, "$ncc_groups:", ""),
    each.value.group
  )
  linked_vpn_tunnels {
    uris                       = each.value.tunnel_self_link
    site_to_site_data_transfer = true
    include_import_ranges      = ["ALL_IPV4_RANGES"]
  }
  depends_on = [module.vpn-ha]
}



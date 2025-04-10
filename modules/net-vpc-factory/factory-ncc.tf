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

# tfdoc:file:description NCC factory.

locals {
  ncc_hubs = { for k, v in local.network_projects : "${k}/${v.ncc_hub_config.name}" =>
    {
      name            = v.ncc_hub_config.name
      project_id      = module.projects[k].id
      description     = try(v.ncc_hub_config.description, "Terraform-managed")
      export_psc      = try(v.ncc_hub_config.export_psc, true)
      preset_topology = try(v.ncc_hub_config.preset_topology, "MESH")
    }
    if try(v.ncc_hub_config != null, false)
  }

  ncc_groups = merge(flatten([for k, v in local.network_projects :
    {
      for gk, gv in try(v.ncc_hub_config.groups, {}) : "${k}/${v.ncc_hub_config.name}/${gk}" =>
      {
        name        = gk
        project     = module.projects[k].id
        hub         = google_network_connectivity_hub.default["${k}/${v.ncc_hub_config.name}"].id
        description = try(gv.description, "Terraform-managed")
        labels      = try(gv.labels, {})
        auto_accept = [for project_key in try(gv.auto_accept, []) : module.projects[project_key].id]
      }
    }
    if try(v.ncc_hub_config != null, false)
  ])...)

  ncc_vpn_spokes = merge(flatten([
    for factory_key, factory_config in local.network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for vpn_key, vpn_config in try(vpc_config.vpn_config, {}) : {
          "${factory_key}/${vpc_key}/${vpn_key}" = {
            name             = replace("${factory_key}/${vpc_key}/${vpn_key}", "/", "-")
            project_id       = module.projects[factory_key].id
            hub              = google_network_connectivity_hub.default[vpn_config.ncc_spoke_config.hub].id
            location         = vpn_config.region
            description      = lookup(vpn_config.ncc_spoke_config, "description", "Terraform-managed.")
            labels           = lookup(vpn_config.ncc_spoke_config, "labels", {})
            tunnel_self_link = [for t, _ in vpn_config.tunnels : module.vpn-ha["${factory_key}/${vpc_key}/${vpn_key}"].tunnel_self_links[t]]
          }
        }
        if try(vpn_config.ncc_spoke_config != null, false)
      ]
    ]
  ])...)

  ncc_vpc_spokes = merge(flatten([
    for factory_key, factory_config in local.network_projects : {
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : "${factory_key}/${vpc_key}" => merge(vpc_config.ncc_config, {
        project_id            = module.projects[factory_key].id
        network_self_link     = module.vpc["${factory_key}/${vpc_key}"].self_link
        labels                = try(vpc_config.ncc_config.labels, {})
        hub                   = google_network_connectivity_hub.default[vpc_config.ncc_config.hub].id
        description           = try(vpc_config.ncc_config.description, "Terraform-managed")
        exclude_export_ranges = try(vpc_config.ncc_config.exclude_export_ranges, null)
        include_export_ranges = try(vpc_config.ncc_config.include_export_ranges, null)
        group                 = try(google_network_connectivity_group.default[vpc_config.ncc_config.group].id, null)
      })
      if try(vpc_config.ncc_config != null, false)
    }
  ])...)

}

resource "google_network_connectivity_hub" "default" {
  for_each        = local.ncc_hubs
  name            = each.value.name
  description     = each.value.description
  export_psc      = each.value.export_psc
  preset_topology = each.value.preset_topology
  project         = each.value.project_id
}

resource "google_network_connectivity_spoke" "vpcs" {
  for_each    = local.ncc_vpc_spokes
  project     = each.value.project_id
  name        = replace(each.key, "/", "-")
  location    = "global"
  description = each.value.description
  labels      = each.value.labels
  hub         = each.value.hub
  linked_vpc_network {
    uri                   = each.value.network_self_link
    exclude_export_ranges = each.value.exclude_export_ranges
    include_export_ranges = each.value.include_export_ranges
  }
  depends_on = [google_network_connectivity_hub.default]
  group      = each.value.group
}

resource "google_network_connectivity_group" "default" {
  for_each    = local.ncc_groups
  project     = each.value.project
  name        = each.value.name
  hub         = each.value.hub
  labels      = each.value.labels
  description = each.value.description
  dynamic "auto_accept" {
    for_each = try(each.value.auto_accept != null, false) ? [""] : []
    content {
      auto_accept_projects = each.value.auto_accept
    }
  }
  depends_on = [google_network_connectivity_hub.default]
}

resource "google_network_connectivity_spoke" "tunnels" {
  for_each    = local.ncc_vpn_spokes
  project     = each.value.project_id
  name        = each.value.name
  location    = each.value.location
  description = each.value.description
  labels      = each.value.labels
  hub         = each.value.hub
  linked_vpn_tunnels {
    uris                       = each.value.tunnel_self_link
    site_to_site_data_transfer = true
    include_import_ranges      = ["ALL_IPV4_RANGES"]
  }
  depends_on = [module.vpn-ha]
}

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

# tfdoc:file:description NCC

locals {

  _ncc_path = try(
    pathexpand(var.factories_config.ncc-hubs), null
  )

  _ncc_files = try(
    fileset(local._ncc_path, "**/*.yaml"),
    []
  )

  _ncc_preprocess = [
    for f in local._ncc_files : yamldecode(file("${coalesce(local._ncc_path, "-")}/${f}"))
  ]

  ctx_ncc = {
    groups = { for k, v in google_network_connectivity_group.default : k => v.id }
    hubs   = { for k, v in google_network_connectivity_hub.default : k => v.id }
  }

  ncc_hubs = { for k, v in local._ncc_preprocess : v.name =>
    {
      project_id      = lookup(local.ctx_projects.project_ids, replace(v.project_id, "$project_ids:", ""), v.project_id)
      description     = try(v.description, "Terraform-managed")
      export_psc      = try(v.export_psc, true)
      preset_topology = try(v.preset_topology, "MESH")
    }
  }

  ncc_groups = merge(flatten([for k, v in local._ncc_preprocess :
    {
      for gk, gv in try(v.groups, {}) : "${v.name}/${gk}" =>
      {
        name        = gk
        project_id  = lookup(local.ctx_projects.project_ids, replace(v.project_id, "$project_ids:", ""), v.project_id)
        hub         = v.name
        description = try(gv.description, "Terraform-managed")
        labels      = try(gv.labels, {})
        auto_accept = [for project_key in try(gv.auto_accept, []) : lookup(local.ctx_projects.project_ids, replace(project_key, "$project_ids:", ""), project_key)]
      }
    }
  ])...)

}

resource "google_network_connectivity_hub" "default" {
  for_each        = local.ncc_hubs
  name            = each.key
  description     = each.value.description
  export_psc      = each.value.export_psc
  preset_topology = each.value.preset_topology
  project         = each.value.project_id
}

resource "google_network_connectivity_group" "default" {
  for_each    = local.ncc_groups
  project     = each.value.project_id
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

# resource "google_network_connectivity_spoke" "tunnels" {
#   for_each    = local.ncc_vpn_spokes
#   project     = each.value.project_id
#   name        = each.value.name
#   location    = each.value.location
#   description = each.value.description
#   labels      = each.value.labels
#   hub         = each.value.hub
#   linked_vpn_tunnels {
#     uris                       = each.value.tunnel_self_link
#     site_to_site_data_transfer = true
#     include_import_ranges      = ["ALL_IPV4_RANGES"]
#   }
#   depends_on = [module.vpn-ha]
# }


# resource "google_network_connectivity_spoke" "vpcs" {
#   for_each    = local.ncc_vpc_spokes
#   project     = each.value.project_id
#   name        = replace(each.key, "/", "-")
#   location    = "global"
#   description = each.value.description
#   labels      = each.value.labels
#   hub         = each.value.hub
#   linked_vpc_network {
#     uri                   = each.value.network_self_link
#     exclude_export_ranges = each.value.exclude_export_ranges
#     include_export_ranges = each.value.include_export_ranges
#   }
#   depends_on = [google_network_connectivity_hub.default]
#   group      = each.value.group
# }

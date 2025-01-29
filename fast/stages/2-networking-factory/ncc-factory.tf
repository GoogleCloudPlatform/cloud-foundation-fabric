# TODO(sruffilli) Brainstorm on how to handle NCC hubs.
# Hubs strictly depend on projects (not VPCs), hence if we manually
# handle projects, it kinda make sense to also manually handle NCC Hubs.
#
# OTOH I would like to create network recipes for the different connectivity
# metodologies, which requires handling hubs in the factory.
#
# My vote is for the latter

locals {
  # read and decode factory files
  _ncc_hubs_path = try(
    pathexpand(var.factories_config.ncc_hubs), null
  )
  _ncc_hubs_files = try(
    fileset(local._ncc_hubs_path, "**/*.yaml"),
    []
  )
  _ncc_hubs = {
    for f in local._ncc_hubs_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._ncc_hubs_path, "-")}/${f}"
    ))
  }

  ncc_spokes = {
    for k, v in local._vpcs : k => merge(v.ncc_configs, {
      project_id  = try(v.project_id, null)
      network     = module.vpcs[k].self_link
      hub         = try(google_network_connectivity_hub.hub[v.ncc_configs.hub].id, v.var.ncc_hubs_configs.hub)
      description = try(v.description, "Terraform-managed.")
      labels      = try(v.labels, {})
      }
    )
    if try(v.ncc_configs != null, false)
  }


  ncc_hubs = merge(
    # normalize factory data attributes with defaults and nulls
    {
      for k, v in local._ncc_hubs : k => merge(v, {
        description     = try(v.description, "Terraform-managed.")
        preset_topology = try(v.preset_topology, "MESH")
        export_psc      = try(v.export_psc, true)
      })
    },
    var.ncc_hubs_configs
  )
}

resource "google_network_connectivity_hub" "hub" {
  for_each        = local.ncc_hubs
  name            = each.value.name
  project         = each.value.project_id
  description     = each.value.description
  preset_topology = each.value.preset_topology
  export_psc      = each.value.export_psc
}

resource "google_network_connectivity_spoke" "primary" {
  for_each    = local.ncc_spokes
  project     = each.value.project_id
  name        = each.key
  location    = "global"
  description = each.value.description
  labels      = each.value.labels
  hub         = each.value.hub
  linked_vpc_network {
    uri = each.value.network
  }
  depends_on = [google_network_connectivity_hub.hub]
}


# TODO(sruffilli): support google_network_connectivity_group

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
  ncc_hubs = { for k, v in local._network_projects : "${k}/${v.ncc_hub_configs.name}" => {
    name            = v.ncc_hub_configs.name
    project_id      = module.projects[k].id
    description     = try(v.ncc_hub_configs.description, "Terraform-managed")
    export_psc      = try(v.ncc_hub_configs.export_psc, true)
    preset_topology = try(v.ncc_hub_configs.preset_topology, "MESH")
    }
    if try(v.ncc_hub_configs != null, false)
  }

  ncc_spokes = merge(flatten([
    for factory_key, factory_config in local._network_projects : {
      for vpc_key, vpc_config in try(factory_config.vpc_configs, {}) : "${factory_key}/${vpc_key}" => merge(vpc_config.ncc_configs, {
        project_id        = module.projects[factory_key].id
        network_self_link = module.vpcs["${factory_key}/${vpc_key}"].self_link
        labels            = try(vpc_config.ncc_configs.labels, {})
        hub               = google_network_connectivity_hub.hub[vpc_config.ncc_configs.hub].id
        description       = try(vpc_config.ncc_configs.description, "Terraform-managed")
      })
      if try(vpc_config.ncc_configs != null, false)
    }
  ])...)

}

resource "google_network_connectivity_hub" "hub" {
  for_each        = local.ncc_hubs
  name            = each.value.name
  description     = each.value.description
  export_psc      = each.value.export_psc
  preset_topology = each.value.preset_topology
  project         = each.value.project_id
}

resource "google_network_connectivity_spoke" "primary" {
  for_each    = local.ncc_spokes
  project     = each.value.project_id
  name        = replace(each.key, "/", "-")
  location    = "global"
  description = each.value.description
  labels      = each.value.labels
  hub         = each.value.hub
  linked_vpc_network {
    uri = each.value.network_self_link
  }
  depends_on = [google_network_connectivity_hub.hub]
}


# TODO(sruffilli): support google_network_connectivity_group

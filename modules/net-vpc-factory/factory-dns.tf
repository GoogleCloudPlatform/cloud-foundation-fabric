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
  dns_zone_entries = flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_configs, {}) : [
        for zone_key, zone in try(vpc_config.dns_zones, {}) : {
          key = "${factory_key}/${vpc_key}/${zone_key}"
          value = merge(
            {
              name          = replace("${vpc_key}-${zone_key}", "/", "-")
              project_id    = module.projects[factory_key].id
              description   = try(zone.description, "Terraform-managed.")
              force_destroy = try(zone.force_destroy, null)
              iam           = try(zone.iam, null)
              recordsets    = try(zone.recordsets, null)
            },
            # TODO(sruffilli)(?) I don't like how this is implemented, however I can't think of a better way
            # The different zone_config flavors have a different structure (as they should), and I need to try to replace
            # values for peer_network and client_networks with reference to module.vpc[foobar].self_link.
            # Which is easy in principle, however the naive approach which parses everything and only updates
            # those fields doesn't work, as either you try to reference a non-existing field, or end up creating 
            # null private/peering/forwarding members, which isn't supported by the upstream module.
            {
              zone_config = merge(
                { domain = try(zone.zone_config.domain, null) },
                contains(keys(try(zone.zone_config, {})), "private") ? {
                  private = {
                    service_directory_namespace = try(zone.zone_config.private.service_directory_namespace, null)
                    client_networks = [
                      for net in zone.zone_config.private.client_networks :
                      try(module.vpcs[net].self_link, net)
                    ]
                  }
                } : {},
                contains(keys(try(zone.zone_config, {})), "peering") ? {
                  peering = {
                    peer_network = try(module.vpcs[zone.zone_config.peering.peer_network].self_link, zone.zone_config.peering.peer_network),
                    client_networks = [
                      for net in zone.zone_config.peering.client_networks :
                      try(module.vpcs[net].self_link, net)
                    ]
                  }
                } : {},
                contains(keys(try(zone.zone_config, {})), "forwarding") ? {
                  forwarding = {
                    forwarders = try(zone.zone_config.forwarding.forwarders, {}),
                    client_networks = [
                      for net in zone.zone_config.forwarding.client_networks :
                      try(module.vpcs[net].self_link, net)
                    ]
                  }
                } : {}
              )
            }
          )
        }
      ]
    ]
  ])

  # Convert the flattened list into a map.
  dns_zones = { for entry in local.dns_zone_entries : entry.key => entry.value }
}

module "dns-zones" {
  source        = "../../../modules/dns"
  for_each      = local.dns_zones
  project_id    = each.value.project_id
  name          = each.value.name
  description   = each.value.description
  force_destroy = each.value.force_destroy
  iam           = each.value.iam
  zone_config   = each.value.zone_config
  recordsets    = each.value.recordsets
  depends_on    = [module.vpcs]
}

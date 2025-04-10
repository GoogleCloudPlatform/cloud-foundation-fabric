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

# tfdoc:file:description DNS factory.

locals {
  dns_zone_entries = flatten([
    for factory_key, factory_config in local.network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
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
            {
              zone_config = merge(
                { domain = try(zone.zone_config.domain, null) },
                contains(keys(try(zone.zone_config, {})), "private") ? {
                  private = {
                    service_directory_namespace = try(zone.zone_config.private.service_directory_namespace, null)
                    client_networks = [
                      for net in zone.zone_config.private.client_networks :
                      try(module.vpc[net].self_link, net)
                    ]
                  }
                } : {},
                contains(keys(try(zone.zone_config, {})), "peering") ? {
                  peering = {
                    peer_network = try(module.vpc[zone.zone_config.peering.peer_network].self_link, zone.zone_config.peering.peer_network),
                    client_networks = [
                      for net in zone.zone_config.peering.client_networks :
                      try(module.vpc[net].self_link, net)
                    ]
                  }
                } : {},
                contains(keys(try(zone.zone_config, {})), "forwarding") ? {
                  forwarding = {
                    forwarders = try(zone.zone_config.forwarding.forwarders, {}),
                    client_networks = [
                      for net in zone.zone_config.forwarding.client_networks :
                      try(module.vpc[net].self_link, net)
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
  source        = "../dns"
  for_each      = local.dns_zones
  project_id    = each.value.project_id
  name          = each.value.name
  description   = each.value.description
  force_destroy = each.value.force_destroy
  iam           = each.value.iam
  zone_config   = each.value.zone_config
  recordsets    = each.value.recordsets
  depends_on    = [module.vpc]
}

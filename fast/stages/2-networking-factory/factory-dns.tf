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

  dns_zones_cn_private = merge(flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_configs, {}) : [
        for k, v in try(vpc_config.dns_zones, {}) : {
          "${factory_key}/${vpc_key}/${k}" = {
            name          = replace("${vpc_key}-${k}", "/", "-")
            project_id    = module.projects[factory_key].id
            description   = try(v.description, "Terraform-managed.")
            force_destroy = try(v.force_destroy, null)
            iam           = try(v.iam, null)
            recordsets    = try(v.recordsets, {})
            zone_config = {
              domain                      = try(v.zone_config.domain, null)
              service_directory_namespace = try(v.zone_config.service_directory_namespace, null)
              private = {
                client_networks = [for net in v.zone_config.private.client_networks : try(module.vpcs[net].self_link, net)]
              }
            }
          }
        }
        if try(v.zone_config.private != null, false)
      ]
    ]
  ])...)

  dns_zones_cn_peering = merge(flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_configs, {}) : [
        for k, v in try(vpc_config.dns_zones, {}) : {
          "${factory_key}/${vpc_key}/${k}" = {
            name          = replace("${vpc_key}-${k}", "/", "-")
            project_id    = factory_key
            description   = try(v.description, "Terraform-managed.")
            force_destroy = try(v.force_destroy, null)
            iam           = try(v.iam, null)
            recordsets    = try(v.recordsets, {})
            zone_config = {
              domain       = try(v.zone_config.domain, null)
              peer_network = try(v.zone_config.peer_network, null)
              peering = {
                client_networks = [for net in v.zone_config.peering.client_networks : try(module.vpcs[net].self_link, net)]
              }
            }
          }
        }
        if try(v.zone_config.peering != null, false)
      ]
    ]
  ])...)

  dns_zones_cn_forwarding = merge(flatten([
    for factory_key, factory_config in local._network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_configs, {}) : [
        for k, v in try(vpc_config.dns_zones, {}) : {
          "${factory_key}/${vpc_key}/${k}" = {
            name          = replace("${vpc_key}-${k}", "/", "-")
            project_id    = factory_key
            description   = try(v.description, "Terraform-managed.")
            force_destroy = try(v.force_destroy, null)
            iam           = try(v.iam, null)
            recordsets    = try(v.recordsets, {})
            zone_config = {
              domain       = try(v.zone_config.domain, null)
              peer_network = try(v.zone_config.peer_network, null)
              forwarding = {
                forwarders      = try(v.zone_config.forwarding.forwarders, {})
                client_networks = [for net in v.zone_config.forwarding.client_networks : try(module.vpcs[net].self_link, net)]
              }
            }
          }
        }
        if try(v.zone_config.forwarding != null, false)
      ]
    ]
  ])...)

  dns_zones = merge(local.dns_zones_cn_private, local.dns_zones_cn_peering, local.dns_zones_cn_forwarding)

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

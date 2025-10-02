# /**
#  * Copyright 2025 Google LLC
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *      http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */

# # tfdoc:file:description VPC and firewall factory.

locals {

  _dns_path = try(
    pathexpand(var.factories_config.dns), null
  )

  _dns_files = try(
    fileset(local._dns_path, "**/*.yaml"),
    []
  )

  _dns_preprocess = [
    for f in local._dns_files : merge(yamldecode(file("${coalesce(local._dns_path, "-")}/${f}")), {
      key = replace(f, ".yaml", "")
    })
  ]

  dns_zones = {
    for zone_config in local._dns_preprocess : "${zone_config.key}" => merge(zone_config, {
      project_id    = zone_config.project_id
      name          = replace(zone_config.key, "/", "-")
      description   = try(zone_config.description, "Terraform-managed.")
      force_destroy = try(zone_config.force_destroy, null)
      iam           = try(zone_config.iam, null)
      recordsets    = try(zone_config.recordsets, null)
      }, {
      zone_config = merge(
        { domain = try(zone_config.domain, null) },
        contains(keys(try(zone_config, {})), "private") ? {
          private = {
            service_directory_namespace = try(zone_config.private.service_directory_namespace, null)
            client_networks             = zone_config.private.client_networks
          }
        } : {},
        contains(keys(try(zone_config, {})), "peering") ? {
          peering = {
            peer_network    = zone_config.peering.peer_network
            client_networks = zone_config.peering.client_networks
          }
        } : {},
        contains(keys(try(zone_config, {})), "forwarding") ? {
          forwarding = {
            forwarders      = try(zone_config.forwarding.forwarders, {}),
            client_networks = zone_config.forwarding.client_networks
          }
        } : {}
      )
    })
  }
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
  context = {
    project_ids = local.ctx_projects.project_ids
    vpcs        = local.ctx_vpcs.self_links
  }
  depends_on = [module.vpcs]
}

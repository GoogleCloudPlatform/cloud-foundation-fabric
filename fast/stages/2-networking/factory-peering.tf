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

# tfdoc:file:description VPC Peering factory.

locals {

  peering_configs = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : {
      for peering_key, peering_configs in try(vpc_config.peering_config, {}) :
      "${vpc_key}/${peering_key}" => merge(peering_configs, {
        project                             = vpc_config.project_id
        name                                = replace("${vpc_key}/${peering_key}", "/", "-")
        local_network                       = vpc_key
        peer_network                        = peering_configs.peer_network
        export_custom_routes                = try(peering_configs.routes_config.export, true)
        import_custom_routes                = try(peering_configs.routes_config.import, true)
        export_subnet_routes_with_public_ip = try(peering_configs.routes_config.public_export, null)
        import_subnet_routes_with_public_ip = try(peering_configs.routes_config.public_import, null)
        stack_type                          = try(peering_configs.stack_type, null)
        }
      )
    }
  ])...)
}

resource "google_compute_network_peering" "default" {
  for_each = local.peering_configs
  name     = each.value.name
  network = lookup(local.ctx_vpcs.self_links,
    replace(each.value.local_network, "$networks:", ""),
    each.value.local_network
  )
  peer_network = lookup(local.ctx_vpcs.self_links,
    replace(each.value.peer_network, "$networks:", ""),
    each.value.peer_network
  )
  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
  stack_type                          = each.value.stack_type
}

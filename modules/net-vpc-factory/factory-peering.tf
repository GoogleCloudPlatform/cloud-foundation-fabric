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

# tfdoc:file:description Peering factory.

locals {
  peerings = merge(flatten([
    for factory_key, factory_config in local.network_projects : [
      for vpc_key, vpc_config in try(factory_config.vpc_config, {}) : [
        for k, v in try(vpc_config.peering_config, {}) : {
          "${factory_key}/${vpc_key}/${k}" = {
            project                             = factory_key
            name                                = replace("${vpc_key}/${k}", "/", "-")
            local_network                       = module.vpc["${factory_key}/${vpc_key}"].self_link
            peer_network                        = module.vpc[v.peer_network].self_link
            export_custom_routes                = try(v.routes_config.export, true)
            import_custom_routes                = try(v.routes_config.import, true)
            export_subnet_routes_with_public_ip = try(v.routes_config.public_export, null)
            import_subnet_routes_with_public_ip = try(v.routes_config.public_import, null)
            stack_type                          = try(v.stack_type, null)
          }
        }
      ]
    ]
  ])...)
}

resource "google_compute_network_peering" "default" {
  for_each                            = local.peerings
  name                                = each.value.name
  network                             = each.value.local_network
  peer_network                        = each.value.peer_network
  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
  stack_type                          = each.value.stack_type
}

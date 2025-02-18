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

# tfdoc:file:description FAST context locals

locals {
  # extract the map of all subnet ids and their networks
  _subnet_ids = {
    for k, v in local._all_instances : v.subnet_id => v.network_id...
  }
  # extract attributes from subnet ids
  _subnet_attrs = {
    for k, v in local._subnet_ids : k => merge(
      {
        id           = k
        network_id   = v[0]
        region       = split("/", k)[0]
        region_alias = lookup(var.regions, split("/", k)[0], split("/", k)[0])
      },
      !startswith(k, "projects/") ? {} : {
        region = split("/", k)[3]
      }
    )
  }
  # recompose subnet ids checking for context substitutions
  _subnets = {
    for k, v in local._subnet_attrs : k => merge(v, v.region_alias == null ? {} : {
      id     = try(replace(v.id, v.region, v.region_alias))
      region = coalesce(v.region_alias, v.region)
    })
  }
  # derive product of instances and zones and expand instance contexts
  instances = flatten([
    for k, v in local._all_instances : [
      for z in v.zones : merge(v, {
        name       = "${var.name}-${k}-${z}"
        network_id = lookup(var.vpc_self_links, v.network_id, v.network_id)
        project_id = lookup(var.host_project_ids, v.project_id, v.project_id)
        subnet_id = try(
          var.subnet_self_links[v.network_id][local._subnets[v.subnet_id].id],
          v.subnet_id
        )
        zone = "${local._subnets[v.subnet_id].region_alias}-${z}"
      })
    ]
  ])
  # extract service account emails for easy reference
  service_account_emails = {
    for k, v in module.service-accounts : k => v.email
  }
  # expand service account projects
  service_accounts = {
    for k, v in local._all_service_accounts : k => merge(v, {
      project_id = lookup(var.host_project_ids, v.project_id, v.project_id)
    })
  }
}

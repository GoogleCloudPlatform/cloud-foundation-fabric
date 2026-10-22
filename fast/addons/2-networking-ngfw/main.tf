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

locals {
  aliased_project_id = lookup(
    local.ctx_lookup.project_ids, var.project_id, var.project_id
  )
  ctx = merge(var.context, {
    ca_ids = merge(
      var.context.ca_ids,
      merge([
        for pk, pv in var.ca_pools : {
          for ck, cv in pv.ca_ids : "${pk}/${ck}" => cv
        }
      ]...)
    )
    ca_pools = merge(
      var.context.ca_pools,
      { for k, v in var.ca_pools : k => v.id }
    )
    project_ids = merge(
      var.context.project_ids,
      var.host_project_ids
    )
    vpcs = merge(
      var.context.vpcs,
      var.vpc_self_links
    )
  })
  ctx_lookup = {
    for k, v in local.ctx : k => merge(
      v,
      { for kk, vv in v : "$${k}:${kk}" => vv }
    ) if k != "condition_vars"
  }
  project_id = try(module.project[0].project_id, local.aliased_project_id)
}

module "project" {
  source        = "../../../modules/project"
  count         = var._fast_debug.skip_datasources == true ? 0 : 1
  name          = local.aliased_project_id
  project_reuse = {}
  service_agents_config = {
    services_enabled = [
      "networksecurity.googleapis.com"
    ]
  }
  services = var.enable_services != true ? [] : [
    "certificatemanager.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "privateca.googleapis.com"
  ]
}

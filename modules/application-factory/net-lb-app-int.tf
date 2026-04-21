/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Phase 4: Internal application load balancers.

locals {
  _net_lb_app_int_raw = {
    for f in try(fileset(local.paths.net_lb_app_int, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.net_lb_app_int}/${f}")
    )
  }
}

module "net-lb-app-int" {
  source   = "../net-lb-app-int"
  for_each = local._net_lb_app_int_raw
  project_id = lookup(
    local.ctx.project_ids, try(each.value.project_id, ""), try(each.value.project_id, null)
  )
  name = try(each.value.name, each.key)
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  description             = try(each.value.description, "Terraform managed.")
  labels                  = try(each.value.labels, {})
  protocol                = try(each.value.protocol, "HTTP")
  ports                   = try(each.value.ports, null)
  address                 = try(each.value.address, null)
  global_access           = try(each.value.global_access, null)
  vpc_config              = each.value.vpc_config
  backend_service_configs = try(each.value.backend_service_configs, {})
  group_configs           = try(each.value.group_configs, {})
  health_check_configs    = try(each.value.health_check_configs, {})
  neg_configs             = try(each.value.neg_configs, {})
  urlmap_config           = try(each.value.urlmap_config, {})
  context                 = local.ctx
  depends_on = [module.compute-vm]
}

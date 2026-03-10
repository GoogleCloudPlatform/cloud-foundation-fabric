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

# tfdoc:file:description Phase 4: Internal TCP/UDP load balancers.

locals {
  _net_lb_int_raw = {
    for f in try(fileset(local.paths.net_lb_int, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.net_lb_int}/${f}")
    )
  }
}

module "net-lb-int" {
  source   = "../net-lb-int"
  for_each = local._net_lb_int_raw
  project_id              = try(each.value.project_id, null)
  name                    = try(each.value.name, each.key)
  region                  = each.value.region
  description             = try(each.value.description, "Terraform managed.")
  labels                  = try(each.value.labels, {})
  service_label           = try(each.value.service_label, null)
  vpc_config              = each.value.vpc_config
  backend_service_config  = try(each.value.backend_service_config, {})
  backends                = try(each.value.backends, [])
  forwarding_rules_config = try(each.value.forwarding_rules_config, { "" = {} })
  group_configs           = try(each.value.group_configs, {})
  health_check            = try(each.value.health_check, null)
  health_check_config = try(each.value.health_check_config, {
    tcp = { port_specification = "USE_SERVING_PORT" }
  })
  context = merge(local.ctx, {
    iam_principals = local.ctx_iam_principals
  })
  depends_on = [module.compute-vm]
}

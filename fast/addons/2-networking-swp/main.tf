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
    var.host_project_ids, var.project_id, var.project_id
  )
  project_id = try(
    module.project[0].project_id, var.project_id
  )
  regions = {
    for k, v in var.locations : k => lookup(var.regions, v, v)
  }
  swp_configs = flatten([
    for r_k, r_v in local.regions : [
      for k, v in var.swp_configs : merge(v, {
        name             = "${var.name}-${k}-${r_k}"
        region           = r_v
        region_shortname = r_k
      })
    ]
  ])
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
    "privateca.googleapis.com"
  ]
}

module "swp" {
  source     = "../../../modules/net-swp"
  for_each   = { for k in local.swp_configs : k.name => k }
  project_id = local.project_id
  region     = each.value.region
  name       = each.key
  network = lookup(
    var.vpc_self_links,
    each.value.network_id,
    each.value.network_id
  )
  subnetwork = lookup(
    lookup(var.subnet_self_links, each.value.network_id, {}),
    "${each.value.region}/${each.value.subnetwork_id}",
    each.value.subnetwork_id
  )
  certificates = each.value.certificates
  factories_config = {
    policy_rules = "${var.factories_config.policy_rules}/${each.key}"
    url_lists    = "${var.factories_config.url_lists}/${each.key}"
  }
  gateway_config        = each.value.gateway_config
  policy_rules_contexts = var.policy_rules_contexts
  service_attachment = (
    each.value.service_attachment == null
    ? null
    : merge(each.value.service_attachment, {
      nat_subnets = [
        for n in each.value.service_attachment.nat_subnets :
        lookup(var.subnet_self_links, "${each.value.region}/${n}", n)
      ]
    })
  )
  tls_inspection_config = {
    id = (
      each.value.tls_inspection_policy_id != null
      ? each.value.tls_inspection_policy_id
      : try(
        google_network_security_tls_inspection_policy.default[each.value.region].id,
        null
      )
    )
  }
}

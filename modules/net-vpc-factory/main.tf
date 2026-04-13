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
  ctx = var.context
  _vpcs_files = try(
    fileset(local.paths.vpcs, "**/.config.yaml"),
    []
  )
  _vpcs_preprocess = [
    for f in local._vpcs_files : merge(
      yamldecode(file("${coalesce(local.paths.vpcs, "-")}/${f}")),
      {
        factory_dirname  = dirname(f)
        factory_basepath = "${local.paths.vpcs}/${dirname(f)}"
      }
    )
    if f != "defaults.yaml"
  ]
  _vpcs = {
    for v in local._vpcs_preprocess : v.factory_dirname => v
  }
  paths = {
    for k, v in var.factories_config.paths : k => try(pathexpand(
      var.factories_config.basepath == null || startswith(v, "/") || startswith(v, ".")
      ? v :
      "${var.factories_config.basepath}/${v}"
    ), null)
  }
  vpcs = {
    for k, v in local._vpcs : k => merge(
      { for k, v in var.data_defaults : k => v if v != null },
      v,
      { for k, v in var.data_overrides : k => v if v != null },
      {
        subnets_factory_config = {
          subnets_folder = try(
            startswith(v.factories_config.subnets, "/") || startswith(v.factories_config.subnets, ".") ? v.factories_config.subnets :
            "${v.factory_basepath}/${v.factories_config.subnets}",
            "${v.factory_basepath}/subnets"
          )
        }
        firewall_factory_config = {
          rules_folder = try(
            startswith(v.factories_config.firewall_rules, "/") || startswith(v.factories_config.firewall_rules, ".") ? v.factories_config.firewall_rules :
            "${v.factory_basepath}/${v.factories_config.firewall_rules}",
            "${v.factory_basepath}/firewall-rules"
          )
        }
      }
    )
  }
}

module "vpcs" {
  source                            = "../net-vpc"
  for_each                          = local.vpcs
  context                           = local.ctx
  project_id                        = try(each.value.project_id, null)
  name                              = try(each.value.name, null)
  auto_create_subnetworks           = try(each.value.auto_create_subnetworks, null)
  create_googleapis_routes          = try(each.value.create_googleapis_routes, null)
  delete_default_routes_on_create   = try(each.value.delete_default_routes_on_create, true)
  description                       = try(each.value.description, "Terraform managed")
  dns_policy                        = try(each.value.dns_policy, null)
  factories_config                  = each.value.subnets_factory_config
  firewall_policy_enforcement_order = try(each.value.firewall_policy_enforcement_order, "AFTER_CLASSIC_FIREWALL")
  ipv6_config                       = try(each.value.ipv6_config, null)
  mtu                               = try(each.value.mtu, null)
  network_attachments               = try(each.value.network_attachments, {})
  psa_configs                       = try(each.value.psa_configs, [])
  routing_mode                      = try(each.value.routing_mode, "GLOBAL")
}

module "firewall" {
  source = "../net-vpc-firewall"
  for_each = {
    for k, v in local.vpcs : k => v if v.firewall_factory_config != null
  }
  context              = local.ctx
  project_id           = each.value.project_id
  network              = each.value.name
  factories_config     = each.value.firewall_factory_config
  default_rules_config = { disabled = true }
  depends_on           = [module.vpcs]
}

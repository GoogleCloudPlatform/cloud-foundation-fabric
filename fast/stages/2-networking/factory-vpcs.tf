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

# tfdoc:file:description VPC and firewall factory.

locals {

  _vpcs_path = try(
    pathexpand(var.factories_config.vpcs), null
  )

  _vpcs_files = try(
    fileset(local._vpcs_path, "**/.config.yaml"),
    []
  )

  _vpcs_preprocess = [
    for f in local._vpcs_files : merge(yamldecode(file("${coalesce(local._vpcs_path, "-")}/${f}")), {
      factory_basepath = "${local._vpcs_path}/${dirname(f)}"
    })
  ]

  _vpcs = {
    for v in local._vpcs_preprocess : "${v.project_id}/${v.name}" => v
  }

  vpcs = { for k, v in local._vpcs : k => merge(v, {
    auto_create_subnetworks           = try(v.auto_create_subnetworks, false)
    project_id                        = v.project_id
    description                       = try(v.description, "Terraform managed")
    create_googleapis_routes          = try(v.create_googleapis_routes, {})
    delete_default_routes_on_create   = try(v.delete_default_routes_on_create, false)
    dns_policy                        = try(v.dns_policy, {})
    firewall_policy_enforcement_order = try(v.firewall_policy_enforcement_order, "AFTER_CLASSIC_FIREWALL")
    ipv6_config                       = try(v.ipv6_config, {})
    mtu                               = try(v.mtu, null)
    name                              = v.name
    network_attachments               = try(v.network_attachments, {})
    policy_based_routes               = try(v.policy_based_routes, {})
    psa_config                        = try(v.psa_config, [])
    routes                            = try(v.routes, {})
    routing_mode                      = try(v.routing_mode, "GLOBAL")
    subnets_factory_config = {
      subnets_folder = "${v.factory_basepath}/subnets"
    }
    firewall_factory_config = {
      rules_folder = "${v.factory_basepath}/firewall-rules"
    }
    peering_config = try(v.peering_config, {})
    vpn_config     = try(v.vpn_config, {})
    })
  }
}

module "vpc" {
  source                            = "../../../modules/net-vpc"
  for_each                          = local.vpcs
  project_id                        = each.value.project_id
  name                              = each.value.name
  description                       = each.value.description
  auto_create_subnetworks           = each.value.auto_create_subnetworks
  create_googleapis_routes          = each.value.create_googleapis_routes
  delete_default_routes_on_create   = each.value.delete_default_routes_on_create
  dns_policy                        = each.value.dns_policy
  factories_config                  = each.value.subnets_factory_config
  firewall_policy_enforcement_order = each.value.firewall_policy_enforcement_order
  ipv6_config                       = each.value.ipv6_config
  mtu                               = each.value.mtu
  network_attachments               = each.value.network_attachments
  policy_based_routes               = each.value.policy_based_routes
  psa_configs                       = each.value.psa_config
  routes                            = each.value.routes
  routing_mode                      = each.value.routing_mode
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, module.factory.project_ids)
  })
  depends_on = [module.factory]
}

module "firewall" {
  source               = "../../../modules/net-vpc-firewall"
  for_each             = { for k, v in local.vpcs : k => v if v.firewall_factory_config != null }
  project_id           = each.value.project_id
  network              = each.value.name
  factories_config     = each.value.firewall_factory_config
  default_rules_config = { disabled = true }
  context = merge(local.ctx, {
    project_ids = merge(local.ctx.project_ids, module.factory.project_ids)
  })
  depends_on = [module.vpc]
}

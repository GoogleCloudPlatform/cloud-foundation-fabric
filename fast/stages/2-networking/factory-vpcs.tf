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

# tfdoc:file:description VPC and firewall rules factory.

locals {
  _vpcs_path = try(
    pathexpand(var.factories_config.vpcs), null
  )
  _vpcs_files = try(
    fileset(local._vpcs_path, "**/.config.yaml"),
    []
  )
  _vpcs_preprocess = [
    for f in local._vpcs_files : merge(
      yamldecode(file("${coalesce(local._vpcs_path, "-")}/${f}")),
      {
        factory_dirname  = dirname(f)
        factory_basepath = "${local._vpcs_path}/${dirname(f)}"
      }
    )
  ]
  _vpcs = {
    for v in local._vpcs_preprocess : v.factory_dirname => v
  }
  vpcs = {
    for k, v in local._vpcs : k => merge(
      local.vpc_defaults, v,
      {
        project_id                        = v.project_id
        description                       = try(v.description, "Terraform managed")
        create_googleapis_routes          = try(v.create_googleapis_routes, {})
        delete_default_routes_on_create   = try(v.delete_default_routes_on_create, true)
        dns_policy                        = try(v.dns_policy, null)
        firewall_policy_enforcement_order = try(v.firewall_policy_enforcement_order, "AFTER_CLASSIC_FIREWALL")
        ipv6_config                       = try(v.ipv6_config, {})
        name                              = v.name
        network_attachments               = try(v.network_attachments, {})
        policy_based_routes               = try(v.policy_based_routes, {})
        psa_configs                       = try(v.psa_configs, [])
        routes                            = try(v.routes, {})
        routing_mode                      = try(v.routing_mode, "GLOBAL")
        subnets_private_nat               = try(v.subnets_private_nat, [])
        subnets_proxy_only                = try(v.subnets_proxy_only, [])
        subnets_psc                       = try(v.subnets_psc, [])
        subnets                           = try(v.subnets, [])
        subnets_factory_config = {
          subnets_folder = "${v.factory_basepath}/subnets"
        }
        firewall_factory_config = {
          rules_folder = "${v.factory_basepath}/firewall-rules"
        }
        peering_config = try(v.peering_config, {})
        vpn_config     = try(v.vpn_config, {})
      }
    )
  }
  ctx_vpcs = {
    ids        = { for k, v in module.vpc-factory.vpcs : k => v.id }
    names      = { for k, v in module.vpc-factory.vpcs : k => v.name }
    self_links = { for k, v in module.vpc-factory.vpcs : k => v.self_link }
    subnets_by_vpc = merge([
      for vpc_key, vpc in module.vpc-factory.vpcs : {
        for subnet_key, subnet_self_link in vpc.subnet_self_links :
        "${vpc_key}/${subnet_key}" => subnet_self_link
      }
    ]...)
  }
}

moved {
  from = module.vpcs
  to   = module.vpc-factory.module.vpcs
}

moved {
  from = module.firewall
  to   = module.vpc-factory.module.firewall
}

module "vpc-factory" {
  source           = "../../../modules/net-vpc-factory"
  factories_config = var.factories_config
  context = {
    project_ids = local.ctx_projects.project_ids
    locations   = local.ctx.locations
  }
}

moved {
  from = module.vpc_routes
  to   = module.vpc-routes
}

module "vpc-routes" {
  source   = "../../../modules/net-vpc"
  for_each = local.vpcs
  vpc_reuse = {
    use_data_source = false
    attributes      = { network_id = module.vpc-factory.vpcs[each.key].network_id }
  }
  project_id = each.value.project_id
  name       = each.value.name
  routes     = try(each.value.routes, {})
  context = {
    project_ids = local.ctx_projects.project_ids
    locations   = local.ctx.locations
    addresses   = local.ctx_nva.ilb_addresses
  }
  depends_on = [
    module.projects,
    module.vpc-factory
  ]
}

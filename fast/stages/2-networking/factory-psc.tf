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

# tfdoc:file:description PSC endpoints factory.

locals {
  ctx_all_addresses = merge(
    local.ctx_psc_and_vpc_addresses,
    local.ctx_nva.ilb_addresses
  )
  ctx_psc_and_vpc_addresses = merge(
    local.ctx.addresses,
    local.ctx_addresses.internal,
    local.ctx_addresses.psc,
    local.ctx_psc_endpoints
  )
  ctx_psc_endpoints = merge([
    for vpc_key, mod in module.vpc-psc-endpoints : merge(
      {
        for k, ip in mod.addresses.global_apis :
        "${vpc_key}/global_apis/${k}" => ip
      },
      {
        for k, ip in mod.addresses.published_services :
        "${vpc_key}/published_services/${k}" => ip
      },
      {
        for k, ip in mod.addresses.regional_apis :
        "${vpc_key}/regional_apis/${k}" => ip
      }
    )
  ]...)
}

module "vpc-psc-endpoints" {
  source = "../../../modules/net-psc-endpoint"
  for_each = {
    for k, v in local.vpcs : k => v if length(v.psc_endpoints) > 0
  }

  project_id         = each.value.project_id
  global_apis        = try(each.value.psc_endpoints.global_apis, {})
  published_services = try(each.value.psc_endpoints.published_services, {})
  regional_apis      = try(each.value.psc_endpoints.regional_apis, {})

  context = {
    addresses = merge(
      local.ctx.addresses,
      local.ctx_addresses.internal,
      local.ctx_addresses.psc
    )
    locations           = local.ctx.locations
    networks            = local.ctx_vpcs.self_links
    project_ids         = local.ctx_projects.project_ids
    service_attachments = local.ctx.service_attachments
    subnets             = local.ctx_vpcs.subnets_by_vpc
  }
}

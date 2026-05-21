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

# tfdoc:file:description Arbitrary addresses factory.

module "vpc-addresses" {
  source   = "../../../modules/net-address"
  for_each = { for k, v in local.vpcs : k => v if length(v.addresses) > 0 }

  project_id = each.value.project_id

  external_addresses  = try(each.value.addresses.external, {})
  global_addresses    = try(each.value.addresses.global, {})
  internal_addresses  = try(each.value.addresses.internal, {})
  psa_addresses       = try(each.value.addresses.psa, {})
  psc_addresses       = try(each.value.addresses.psc, {})
  network_attachments = try(each.value.addresses.network_attachments, {})

  context = {
    locations   = local.ctx.locations
    networks    = local.ctx_vpcs.self_links
    project_ids = local.ctx_projects.project_ids
    subnets     = local.ctx_vpcs.subnets_by_vpc
  }
}

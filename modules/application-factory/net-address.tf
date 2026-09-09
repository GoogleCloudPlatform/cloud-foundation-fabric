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

# tfdoc:file:description Phase 1: Reserved IP addresses.

# Each YAML file maps to one net-address module instance which can
# manage several addresses of different types, as the module interface
# is a set of maps. Address names must be unique across files as they are
# merged in context.

locals {
  _net_address_raw = {
    for f in try(fileset(local.paths.net_address, "*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(
      file("${local.paths.net_address}/${f}")
    )
  }
}

module "net-address" {
  source                       = "../net-address"
  for_each                     = local._net_address_raw
  project_id                   = try(each.value.project_id, null)
  external_addresses           = try(each.value.external_addresses, {})
  global_addresses             = try(each.value.global_addresses, {})
  internal_addresses           = try(each.value.internal_addresses, {})
  ipsec_interconnect_addresses = try(each.value.ipsec_interconnect_addresses, {})
  network_attachments          = try(each.value.network_attachments, {})
  psa_addresses                = try(each.value.psa_addresses, {})
  psc_addresses                = try(each.value.psc_addresses, {})
  context                      = local.ctx
}

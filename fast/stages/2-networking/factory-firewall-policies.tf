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

# tfdoc:file:description Firewall policies factory.

locals {
  _firewall_policies_path = try(pathexpand(var.factories_config.firewall-policies), null)
  _firewall_policies_files = local._firewall_policies_path == null ? [] : fileset(
    local._firewall_policies_path, "**/*.yaml"
  )
  _firewall_policies_data = {
    for f in local._firewall_policies_files : replace(f, ".yaml", "") => yamldecode(file("${local._firewall_policies_path}/${f}"))
  }
  firewall_policies = {
    for k, v in local._firewall_policies_data : try(v.name, k) => merge(v, {
      parent        = v.parent_id
      attachments   = { for k in try(v.attachments, []) : k => k }
      ingress_rules = try(v.ingress_rules, {})
      egress_rules  = try(v.egress_rules, {})
    })
  }
}

module "firewall_policies" {
  source      = "../../../modules/net-firewall-policy"
  for_each    = local.firewall_policies
  attachments = each.value.attachments
  name        = each.key
  parent_id   = each.value.parent
  factories_data = {
    egress_rules  = each.value.egress_rules
    ingress_rules = each.value.ingress_rules
  }
  context = {
    folders     = local.ctx_folders
    cidr_ranges = local.ctx.cidr_ranges
  }
}

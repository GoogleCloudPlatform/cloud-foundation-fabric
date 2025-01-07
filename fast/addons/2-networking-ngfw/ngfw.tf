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

# tfdoc:file:description NGFW Enteprise resources.

locals {
  ngfw_associations = flatten([
    for k, v in var.ngfw_config.network_associations : [
      for z in coalesce(v.zones, var.ngfw_config.endpoint_zones) : merge(v, {
        key      = "${z}-${k}"
        location = z
        vpc_id   = lookup(var.vpc_self_links, v.vpc_id, v.vpc_id)
      })
    ]
  ])
  tls_inspection_policies = {
    for k, v in google_network_security_tls_inspection_policy.default :
    k => v.id
  }
}

resource "google_network_security_firewall_endpoint" "default" {
  for_each           = toset(var.ngfw_config.endpoint_zones)
  name               = var.ngfw_config.name
  parent             = "organizations/${var.organization.id}"
  location           = each.key
  billing_project_id = local.project_id
}

resource "google_network_security_firewall_endpoint_association" "default" {
  for_each = { for k in local.ngfw_associations : k.key => k }
  name     = "${var.ngfw_config.name}-${each.value.key}"
  parent   = "projects/${regex("projects/([^/]+)/", each.value.vpc_id)[0]}"
  location = each.value.location
  network  = each.value.vpc_id
  firewall_endpoint = (
    google_network_security_firewall_endpoint.default[each.value.location].id
  )
  # If TLS inspection is enabled, link the regional TLS inspection policy
  tls_inspection_policy = try(
    local.tls_inspection_policies[each.value.tls_inspection_policy], null
  )
}

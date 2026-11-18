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

# tfdoc:file:description Regional PSC endpoints for Google APIs.

locals {
  # the API returns relative resource names, and network, subnetwork and
  # address force replacement, so full self links are trimmed to avoid diffs
  _regional_endpoints = {
    for k, v in var.regional_endpoints : k => merge(v, {
      address = (
        v.address == null
        ? null
        : lookup(local.ctx.addresses, v.address, v.address)
      )
      network = (
        v.network == null
        ? null
        : lookup(local.ctx.networks, v.network, v.network)
      )
      subnetwork = (
        v.subnetwork == null
        ? null
        : lookup(local.ctx.subnets, v.subnetwork, v.subnetwork)
      )
    })
  }
  regional_endpoints = {
    for k, v in local._regional_endpoints : k => merge(v, {
      address = (
        v.address == null
        ? null
        : try(regex("projects/.*", v.address), v.address)
      )
      network = (
        v.network == null
        ? null
        : try(regex("projects/.*", v.network), v.network)
      )
      region = lookup(local.ctx.locations, v.region, v.region)
      subnetwork = (
        v.subnetwork == null
        ? null
        : try(regex("projects/.*", v.subnetwork), v.subnetwork)
      )
    })
  }
}

resource "google_network_connectivity_regional_endpoint" "default" {
  for_each          = local.regional_endpoints
  project           = local.project_id
  name              = coalesce(each.value.name, each.key)
  location          = each.value.region
  target_google_api = each.value.target_google_api
  # access_type is required by the provider, so null means regional access
  access_type     = each.value.global_access == true ? "GLOBAL" : "REGIONAL"
  address         = each.value.address
  deletion_policy = each.value.deletion_policy
  description     = coalesce(each.value.description, "Terraform managed.")
  labels          = each.value.labels
  network         = each.value.network
  subnetwork      = each.value.subnetwork
}

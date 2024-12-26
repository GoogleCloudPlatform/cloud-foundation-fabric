/**
 * Copyright 2023 Google LLC
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

# tfdoc:file:description Private Service Access resources.

locals {
  _psa_configs_ranges = flatten([
    for config in local.psa_configs : [
      for k, v in config.ranges : {
        key   = "${config.key}${k}"
        value = v
      }
    ]
  ])
  _psa_peered_domains = flatten([
    for config in local.psa_configs : [
      for v in config.peered_domains : {
        key              = "${config.key}${trimsuffix(replace(v, ".", "-"), "-")}"
        dns_suffix       = v
        service_producer = config.service_producer
      }
    ]
  ])
  psa_configs = {
    for v in var.psa_configs : v.service_producer => merge(v, {
      key = (
        v.range_prefix != null
        ? (v.range_prefix == "" ? "" : "${v.range_prefix}-")
        : format("%s-", replace(v.service_producer, ".", "-"))
      )
    })
  }
  psa_configs_ranges = {
    for v in local._psa_configs_ranges : v.key => v.value
  }
  psa_peered_domains = {
    for v in local._psa_peered_domains : v.key => v
  }
}

resource "google_compute_global_address" "psa_ranges" {
  for_each      = local.psa_configs_ranges
  project       = var.project_id
  network       = local.network.id
  name          = each.key
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", each.value)[0]
  prefix_length = split("/", each.value)[1]
}

resource "google_service_networking_connection" "psa_connection" {
  for_each                = local.psa_configs
  network                 = local.network.id
  service                 = each.key
  reserved_peering_ranges = formatlist("${each.value.key}%s", keys(each.value.ranges))
  deletion_policy         = each.value.deletion_policy
  depends_on              = [google_compute_global_address.psa_ranges]
}

resource "google_compute_network_peering_routes_config" "psa_routes" {
  for_each = local.psa_configs
  project  = var.project_id
  peering = (
    google_service_networking_connection.psa_connection[each.key].peering
  )
  network              = local.network.name
  export_custom_routes = each.value.export_routes
  import_custom_routes = each.value.import_routes
}

resource "google_service_networking_peered_dns_domain" "name" {
  for_each   = local.psa_peered_domains
  project    = var.project_id
  network    = local.network.name
  name       = each.key
  dns_suffix = each.value.dns_suffix
  service    = each.value.service_producer
  depends_on = [google_service_networking_connection.psa_connection]
}

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
  _psa_config_ranges_list = [for x in var.psa_config : x.ranges]
  psa_config_ranges       = try(merge(local._psa_config_ranges_list...), {})
  psa_config              = { for v in var.psa_config : v.service_producer => v }
  _peered_domains_service_pairs = flatten([
    for v in var.psa_config : [
      for domain in v.peered_domains : {
        domain           = domain
        service_producer = v.service_producer
      }
    ]
  ])
  peered_domains = {
    for v in local._peered_domains_service_pairs : "${v.service_producer}-${v.domain}" => v
  }
}

resource "google_compute_global_address" "psa_ranges" {
  for_each      = local.psa_config_ranges
  project       = var.project_id
  name          = each.key
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", each.value)[0]
  prefix_length = split("/", each.value)[1]
  network       = local.network.id
}

resource "google_service_networking_connection" "psa_connection" {
  for_each = local.psa_config
  network  = local.network.id
  service  = each.value.service_producer
  reserved_peering_ranges = [
    for k, v in each.value.ranges : google_compute_global_address.psa_ranges[k].name
  ]
}

resource "google_compute_network_peering_routes_config" "psa_routes" {
  for_each             = local.psa_config
  project              = var.project_id
  peering              = google_service_networking_connection.psa_connection[each.key].peering
  network              = local.network.name
  export_custom_routes = each.value.export_routes
  import_custom_routes = each.value.import_routes
}

resource "google_service_networking_peered_dns_domain" "name" {
  for_each   = local.peered_domains
  project    = var.project_id
  name       = trimsuffix(replace(each.key, ".", "-"), "-")
  network    = local.network.name
  dns_suffix = each.value.domain
  service    = each.value.service_producer
  depends_on = [google_service_networking_connection.psa_connection]
}

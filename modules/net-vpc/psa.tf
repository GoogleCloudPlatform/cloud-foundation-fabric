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
  psa_config_ranges = try(var.psa_config.ranges, {})
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

moved {
  from = google_service_networking_connection.psa_connection["1"]
  to   = google_service_networking_connection.psa_connection[0]
}

resource "google_service_networking_connection" "psa_connection" {
  count   = var.psa_config != null ? 1 : 0
  network = local.network.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    for k, v in google_compute_global_address.psa_ranges : v.name
  ]
}

moved {
  from = google_compute_network_peering_routes_config.psa_routes["1"]
  to   = google_compute_network_peering_routes_config.psa_routes[0]
}

resource "google_compute_network_peering_routes_config" "psa_routes" {
  count                = var.psa_config != null ? 1 : 0
  project              = var.project_id
  peering              = google_service_networking_connection.psa_connection[0].peering
  network              = local.network.name
  export_custom_routes = var.psa_config.export_routes
  import_custom_routes = var.psa_config.import_routes
}

resource "google_service_networking_peered_dns_domain" "name" {
  for_each   = toset(try(var.psa_config.peered_domains, []))
  project    = var.project_id
  name       = trimsuffix(replace(each.value, ".", "-"), "-")
  network    = local.network.name
  dns_suffix = each.value
  service    = "servicenetworking.googleapis.com"
  depends_on = [google_service_networking_connection.psa_connection]
}

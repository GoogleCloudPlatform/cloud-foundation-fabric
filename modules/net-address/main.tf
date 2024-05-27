/**
 * Copyright 2024 Google LLC
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

resource "google_compute_global_address" "global" {
  for_each    = var.global_addresses
  project     = var.project_id
  name        = coalesce(each.value.name, each.key)
  description = each.value.description
  ip_version  = each.value.ipv6 != null ? "IPV6" : "IPV4"
}

resource "google_compute_address" "external" {
  provider           = google-beta
  for_each           = var.external_addresses
  project            = var.project_id
  name               = coalesce(each.value.name, each.key)
  address_type       = "EXTERNAL"
  description        = each.value.description
  ip_version         = each.value.ipv6 != null ? "IPV6" : "IPV4"
  ipv6_endpoint_type = try(each.value.ipv6.endpoint_type, null)
  labels             = each.value.labels
  network_tier       = each.value.tier
  region             = each.value.region
  subnetwork         = each.value.subnetwork
}

resource "google_compute_address" "internal" {
  provider     = google-beta
  for_each     = var.internal_addresses
  project      = var.project_id
  name         = coalesce(each.value.name, each.key)
  address      = each.value.address
  address_type = "INTERNAL"
  description  = each.value.description
  ip_version   = each.value.ipv6 != null ? "IPV6" : "IPV4"
  labels       = coalesce(each.value.labels, {})
  purpose      = each.value.purpose
  region       = each.value.region
  subnetwork   = each.value.subnetwork
}

resource "google_compute_global_address" "psa" {
  for_each      = var.psa_addresses
  project       = var.project_id
  name          = coalesce(each.value.name, each.key)
  description   = each.value.description
  address       = each.value.address
  address_type  = "INTERNAL"
  network       = each.value.network
  prefix_length = each.value.prefix_length
  purpose       = "VPC_PEERING"
  # labels       = lookup(var.internal_address_labels, each.key, {})
}

resource "google_compute_address" "ipsec_interconnect" {
  for_each      = var.ipsec_interconnect_addresses
  project       = var.project_id
  name          = coalesce(each.value.name, each.key)
  description   = each.value.description
  address       = each.value.address
  address_type  = "INTERNAL"
  region        = each.value.region
  network       = each.value.network
  prefix_length = each.value.prefix_length
  purpose       = "IPSEC_INTERCONNECT"
}


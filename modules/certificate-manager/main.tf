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

resource "google_certificate_manager_certificate_map" "map" {
  count       = var.map == null ? 0 : 1
  project     = var.project_id
  name        = var.map.name
  description = var.map.description
  labels      = var.map.labels
}

resource "google_certificate_manager_certificate_map_entry" "entries" {
  for_each     = try(var.map.entries, {})
  project      = google_certificate_manager_certificate_map.map[0].project
  name         = each.key
  description  = each.value.description
  map          = google_certificate_manager_certificate_map.map[0].name
  labels       = each.value.labels
  certificates = [for v in each.value.certificates : google_certificate_manager_certificate.certificates[v].id]
  hostname     = each.value.hostname
  matcher      = each.value.matcher
}

resource "google_certificate_manager_certificate" "certificates" {
  for_each    = var.certificates
  project     = var.project_id
  name        = each.key
  description = each.value.description
  location    = each.value.location
  scope       = each.value.scope
  labels      = each.value.labels
  dynamic "managed" {
    for_each = each.value.managed == null ? [] : [""]
    content {
      domains            = each.value.managed.domains
      dns_authorizations = each.value.managed.dns_authorizations
      issuance_config    = each.value.managed.issuance_config
    }
  }
  dynamic "self_managed" {
    for_each = each.value.self_managed == null ? [] : [""]
    content {
      pem_certificate = each.value.self_managed.pem_certificate
      pem_private_key = each.value.self_managed.pem_private_key
    }
  }
}

resource "google_certificate_manager_dns_authorization" "dns_authorizations" {
  for_each    = var.dns_authorizations
  project     = var.project_id
  name        = each.key
  location    = each.value.location
  description = each.value.description
  type        = each.value.type
  domain      = each.value.domain
}

resource "google_certificate_manager_certificate_issuance_config" "default" {
  for_each    = var.issuance_configs
  project     = var.project_id
  name        = each.key
  description = each.value.description
  certificate_authority_config {
    certificate_authority_service_config {
      ca_pool = each.value.ca_pool
    }
  }
  lifetime                   = each.value.lifetime
  rotation_window_percentage = each.value.rotation_window_percentage
  key_algorithm              = each.value.key_algorithm
  labels                     = each.value.labels
}

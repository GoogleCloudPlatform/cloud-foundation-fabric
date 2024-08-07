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

locals {
  network_attachments = {
    for k, v in var.network_attachments : k => merge(v, {
      region = regex("regions/([^/]+)", v.subnet_self_link)[0]
      # not using the full self link generates a permadiff
      subnet_self_link = (
        startswith(v.subnet_self_link, "https://")
        ? v.subnet_self_link
        : "https://www.googleapis.com/compute/v1/${v.subnet_self_link}"
      )
    })
  }
  regional_psc = {
    for name, psc in var.psc_addresses : name => psc if psc.region != null

  }
  global_psc = {
    for name, psc in var.psc_addresses : name => psc if psc.region == null
  }
}

resource "google_compute_network_attachment" "default" {
  provider    = google-beta
  for_each    = local.network_attachments
  project     = var.project_id
  region      = each.value.region
  name        = each.key
  description = each.value.description
  connection_preference = (
    each.value.automatic_connection ? "ACCEPT_AUTOMATIC" : "ACCEPT_MANUAL"
  )
  subnetworks           = [each.value.subnet_self_link]
  producer_accept_lists = each.value.producer_accept_lists
  producer_reject_lists = each.value.producer_reject_lists
}

# global PSC services
resource "google_compute_global_address" "psc" {
  for_each     = local.global_psc
  project      = var.project_id
  name         = coalesce(each.value.name, each.key)
  description  = each.value.description
  address      = try(each.value.address, null)
  address_type = "INTERNAL"
  network      = each.value.network
  purpose      = "PRIVATE_SERVICE_CONNECT"
  # labels       = lookup(var.internal_address_labels, each.key, {})
}

resource "google_compute_global_forwarding_rule" "psc_consumer" {
  provider              = google-beta
  for_each              = { for name, psc in local.global_psc : name => psc if psc.service_attachment != null }
  name                  = coalesce(each.value.name, each.key)
  project               = var.project_id
  network               = each.value.network
  ip_address            = google_compute_global_address.psc[each.key].self_link
  load_balancing_scheme = ""
  target                = each.value.service_attachment.psc_service_attachment_link
  # allow_psc_global_access is not currently supported for global
  # forwarding rules. This parameter is included for potential future
  # compatibility.
  allow_psc_global_access = each.value.service_attachment.global_access
}

# regional PSC services
resource "google_compute_address" "psc" {
  for_each     = local.regional_psc
  project      = var.project_id
  name         = coalesce(each.value.name, each.key)
  address      = try(each.value.address, null)
  address_type = "INTERNAL"
  description  = each.value.description
  network      = each.value.network
  # purpose not applicable for regional address
  # purpose      = "PRIVATE_SERVICE_CONNECT"
  region     = each.value.region
  subnetwork = each.value.subnet_self_link
  # labels       = lookup(var.internal_address_labels, each.key, {})
}

resource "google_compute_forwarding_rule" "psc_consumer" {
  provider                = google-beta
  for_each                = { for name, psc in local.regional_psc : name => psc if psc.service_attachment != null }
  name                    = coalesce(each.value.name, each.key)
  project                 = var.project_id
  region                  = each.value.region
  subnetwork              = each.value.subnet_self_link
  ip_address              = google_compute_address.psc[each.key].self_link
  load_balancing_scheme   = ""
  recreate_closed_psc     = true
  target                  = each.value.service_attachment.psc_service_attachment_link
  allow_psc_global_access = each.value.service_attachment.global_access
}

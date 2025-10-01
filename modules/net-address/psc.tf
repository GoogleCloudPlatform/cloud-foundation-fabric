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

# PSC (Private Service Connect) Resources



# Global PSC address
resource "google_compute_global_address" "psc_global" {
  count = var.address_create && var.purpose == "PRIVATE_SERVICE_CONNECT" && var.region == null ? 1 : 0

  project      = local.project_id
  name         = var.name
  description  = var.description
  address      = var.address
  address_type = "INTERNAL"
  network      = local.vpc_id
  purpose      = "PRIVATE_SERVICE_CONNECT"
}

# Global PSC forwarding rule (consumer endpoint)
resource "google_compute_global_forwarding_rule" "psc_consumer_global" {
  provider = google-beta
  count    = var.address_create && var.purpose == "PRIVATE_SERVICE_CONNECT" && var.region == null && var.service_attachment != null ? 1 : 0

  name                    = var.name
  project                 = local.project_id
  network                 = local.vpc_id
  ip_address              = google_compute_global_address.psc_global[0].self_link
  load_balancing_scheme   = ""
  target                  = var.service_attachment.psc_service_attachment_link
  allow_psc_global_access = try(var.service_attachment.global_access, null)
}

# Regional PSC address
resource "google_compute_address" "psc_regional" {
  provider = google-beta
  count    = var.address_create && var.purpose == "PRIVATE_SERVICE_CONNECT" && var.region != null ? 1 : 0

  project      = local.project_id
  name         = var.name
  region       = var.region
  address      = var.address
  address_type = "INTERNAL"
  description  = var.description
  network      = local.vpc_id
  subnetwork   = local.vpc_subnet_id
}

# Regional PSC forwarding rule (consumer endpoint)
resource "google_compute_forwarding_rule" "psc_consumer_regional" {
  provider = google-beta
  count    = var.address_create && var.purpose == "PRIVATE_SERVICE_CONNECT" && var.region != null && var.service_attachment != null ? 1 : 0

  name                    = var.name
  project                 = local.project_id
  region                  = var.region
  subnetwork              = local.vpc_subnet_id
  ip_address              = google_compute_address.psc_regional[0].self_link
  load_balancing_scheme   = ""
  recreate_closed_psc     = true
  target                  = var.service_attachment.psc_service_attachment_link
  allow_psc_global_access = try(var.service_attachment.global_access, null)
}
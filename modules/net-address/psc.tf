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

locals {
  network_attachments = {
    for k, v in var.network_attachments : k => merge(v, {
      region = lookup(
        local.ctx.locations,
        regex("regions/([^/]+)", v.subnet_self_link)[0],
        regex("regions/([^/]+)", v.subnet_self_link)[0]
      )
      # not using the full self link generates a permadiff
      subnet_self_link = lookup(
        local.ctx,
        startswith(v.subnet_self_link, "https://")
        ? v.subnet_self_link
        : "https://www.googleapis.com/compute/v1/${v.subnet_self_link}",
        startswith(v.subnet_self_link, "https://")
        ? v.subnet_self_link
        : "https://www.googleapis.com/compute/v1/${v.subnet_self_link}"
      )
    })
  }
}

resource "google_compute_network_attachment" "default" {
  provider              = google-beta
  for_each              = local.network_attachments
  name                  = each.key
  project               = local.project_id
  description           = each.value.description
  producer_accept_lists = each.value.producer_accept_lists
  producer_reject_lists = each.value.producer_reject_lists
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  subnetworks = [lookup(
    local.ctx.subnets,
    each.value.subnet_self_link,
    each.value.subnet_self_link
  )]
  connection_preference = (
    each.value.automatic_connection
    ? "ACCEPT_AUTOMATIC"
    : "ACCEPT_MANUAL"
  )
}

resource "google_compute_global_address" "psc" {
  for_each     = var.psc_addresses
  project      = local.project_id
  name         = coalesce(each.value.name, each.key)
  description  = coalesce(each.value.description, "Terraform managed.")
  address      = each.value.address
  address_type = "INTERNAL"
  labels       = each.value.labels
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network = lookup(
    local.ctx.networks, each.value.network, each.value.network
  )
}

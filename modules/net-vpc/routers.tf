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

# Cloud Routers for this VPC

resource "google_compute_router" "routers" {
  for_each = var.routers

  project     = local.project_id
  name        = each.key
  region      = each.value.region
  network     = local.network.name
  description = each.value.description

  dynamic "bgp" {
    for_each = each.value.asn != null ? [1] : []
    content {
      asn                = each.value.asn
      keepalive_interval = try(each.value.keepalive_interval, null)
      advertise_mode     = try(each.value.advertise_mode, null)
      advertised_groups  = try(each.value.advertised_groups, null)

      dynamic "advertised_ip_ranges" {
        for_each = each.value.advertised_ip_ranges != null ? each.value.advertised_ip_ranges : {}
        content {
          range       = advertised_ip_ranges.value.range
          description = try(advertised_ip_ranges.value.description, null)
        }
      }
    }
  }
}

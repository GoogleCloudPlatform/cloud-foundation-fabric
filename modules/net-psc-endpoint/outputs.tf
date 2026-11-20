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

output "addresses" {
  description = "Allocated or configured IP addresses for PSC endpoints."
  value = {
    global_apis = {
      for k, v in var.global_apis : k => try(
        google_compute_global_address.global_apis[k].address,
        lookup(local.ctx.addresses, v.address, v.address)
      )
    }
    published_services = {
      for k, v in var.published_services : k => try(
        google_compute_address.published_services[k].address,
        lookup(local.ctx.addresses, v.address, v.address)
      )
    }
    regional_apis = {
      for k, v in var.regional_apis : k => try(
        google_compute_address.regional_apis[k].address,
        lookup(local.ctx.addresses, v.address, v.address)
      )
    }
  }
}

output "global_apis" {
  description = "Allocated resources for global Google APIs PSC endpoints."
  value = {
    for k, v in var.global_apis : k => {
      address         = try(google_compute_global_address.global_apis[k], null)
      forwarding_rule = google_compute_global_forwarding_rule.global_apis[k]
    }
  }
}

output "published_services" {
  description = "Allocated resources for published services PSC endpoints."
  value = {
    for k, v in var.published_services : k => {
      address         = try(google_compute_address.published_services[k], null)
      forwarding_rule = google_compute_forwarding_rule.published_services[k]
    }
  }
}

output "regional_apis" {
  description = "Allocated resources for regional Google APIs PSC endpoints."
  value = {
    for k, v in var.regional_apis : k => {
      address = try(google_compute_address.regional_apis[k], null)
      regional_endpoint = (
        google_network_connectivity_regional_endpoint.regional_apis[k]
      )
    }
  }
}

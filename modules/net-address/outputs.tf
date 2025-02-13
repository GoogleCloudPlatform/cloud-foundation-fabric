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

output "external_addresses" {
  description = "Allocated external addresses."
  value = {
    for address in google_compute_address.external :
    address.name => address
  }
}

output "global_addresses" {
  description = "Allocated global external addresses."
  value = {
    for address in google_compute_global_address.global :
    address.name => address
  }
}

output "internal_addresses" {
  description = "Allocated internal addresses."
  value = {
    for address in google_compute_address.internal :
    address.name => address
  }
}

output "ipsec_interconnect_addresses" {
  description = "Allocated internal addresses for HA VPN over Cloud Interconnect."
  value = {
    for address in google_compute_address.ipsec_interconnect :
    address.name => address
  }
}

output "network_attachment_ids" {
  description = "IDs of network attachments."
  value = {
    for k, v in google_compute_network_attachment.default :
    k => v.id
  }
}

output "psa_addresses" {
  description = "Allocated internal addresses for PSA endpoints."
  value = {
    for address in google_compute_global_address.psa :
    address.name => address
  }
}

output "psc_addresses" {
  description = "Allocated internal addresses for PSC endpoints."
  value = merge(
    {
      for address in google_compute_global_address.psc :
      address.name => address
    },
    {
      for address in google_compute_address.psc :
      address.name => address
    }
  )
}

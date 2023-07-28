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

output "attachment" {
  description = "VLAN Attachment resource."
  value       = google_compute_interconnect_attachment.default
}

output "id" {
  description = "Fully qualified VLAN attachment id."
  value       = google_compute_interconnect_attachment.default.id
}

output "name" {
  description = "The name of the VLAN attachment created."
  value       = google_compute_interconnect_attachment.default.name
}

output "pairing_key" {
  description = "Opaque identifier of an PARTNER attachment used to initiate provisioning with a selected partner."
  value       = google_compute_interconnect_attachment.default.pairing_key
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = local.ipsec_enabled ? one(google_compute_router.encrypted[*]) : one(google_compute_router.unencrypted[*])
}

output "router_interface" {
  description = "Router interface created for the VLAN attachment."
  value       = google_compute_router_interface.default
}

output "router_name" {
  description = "Router name."
  value       = local.router
}

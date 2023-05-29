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

output "overlay_router" {
  description = "Underlay router resource."
  value       = google_compute_router.encrypted-interconnect-overlay-router
}

output "underlay_router" {
  description = "Underlay router resource."
  value       = google_compute_router.encrypted-interconnect-underlay-router
}

output "vlan_attachments" {
  description = "Link to the VLAN Attachment resources."
  value = {
    a = module.va-a.attachment
    b = module.va-a.attachment
  }
}

output "vpn" {
  description = "VPN configuration."
  value = {
    gcp_gateways = {
      a = module.vpngw["a"]
    }
    onprem_gateway = {
      id        = google_compute_external_vpn_gateway.default.id
      interface = google_compute_external_vpn_gateway.default.interface
    }
  }
}


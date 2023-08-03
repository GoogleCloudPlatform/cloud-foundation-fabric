/**
 * Copyright 2022 Google LLC
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


output "bgp_peers" {
  description = "BGP peer resources."
  value = {
    for k, v in google_compute_router_peer.default : k => v
  }
}

output "external_gateway" {
  description = "External VPN gateway resource."
  value       = try(google_compute_external_vpn_gateway.default[0], null)
}

output "id" {
  description = "Fully qualified VPN gateway id."
  value       = google_compute_ha_vpn_gateway.default.id
}

output "random_secret" {
  description = "Generated secret."
  value       = local.secret
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = one(google_compute_router.default[*])
}

output "router_name" {
  description = "Router name."
  value       = local.router
}

output "self_link" {
  description = "HA VPN gateway self link."
  value       = google_compute_ha_vpn_gateway.default.self_link
}

output "tunnels" {
  description = "VPN tunnel resources."
  value = {
    for name in keys(var.tunnels) :
    name => {
      self_link = google_compute_vpn_tunnel.default[name].self_link
      name      = google_compute_vpn_tunnel.default[name].name
      peer_ip   = google_compute_vpn_tunnel.default[name].peer_ip
    }
  }
}

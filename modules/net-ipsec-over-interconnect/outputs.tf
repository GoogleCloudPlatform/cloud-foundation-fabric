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
  value       = google_compute_external_vpn_gateway.default
}

output "gateway" {
  description = "VPN gateway resource."
  value       = google_compute_ha_vpn_gateway.default
}

output "id" {
  description = "Static gateway id."
  value = (
    "projects/${var.project_id}/regions/${var.region}/vpnGateways/${var.name}"
  )
}

output "name" {
  description = "VPN gateway name."
  value       = google_compute_ha_vpn_gateway.default
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

output "tunnel_names" {
  description = "VPN tunnel names."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.default[name].name, null)
  }
}

output "tunnel_self_links" {
  description = "VPN tunnel self links."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.default[name].self_link, null)
  }
}

output "tunnels" {
  description = "VPN tunnel resources."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.default[name], null)
  }
}

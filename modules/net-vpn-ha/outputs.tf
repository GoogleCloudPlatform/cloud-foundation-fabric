
/**
 * Copyright 2019 Google LLC
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

output "gateway" {
  description = "HA VPN gateway resource."
  value       = google_compute_ha_vpn_gateway.ha_gateway
}

output "external_gateway" {
  description = "External VPN gateway resource."
  value = (
    var.peer_external_gateway != null
    ? google_compute_external_vpn_gateway.external_gateway[0]
    : null
  )
}

output "name" {
  description = "VPN gateway name."
  value       = google_compute_ha_vpn_gateway.ha_gateway.name
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = var.router_name == "" ? google_compute_router.router[0] : null
}

output "router_name" {
  description = "Router name."
  value       = local.router
}

output "self_link" {
  description = "HA VPN gateway self link."
  value       = google_compute_ha_vpn_gateway.ha_gateway.self_link
}

output "tunnels" {
  description = "VPN tunnel resources."
  value = {
    for name in keys(var.tunnels) :
    name => google_compute_vpn_tunnel.tunnels[name]
  }
}

output "tunnel_names" {
  description = "VPN tunnel names."
  value = {
    for name in keys(var.tunnels) :
    name => google_compute_vpn_tunnel.tunnels[name].name
  }
}

output "tunnel_self_links" {
  description = "VPN tunnel self links."
  value = {
    for name in keys(var.tunnels) :
    name => google_compute_vpn_tunnel.tunnels[name].self_link
  }
}

output "random_secret" {
  description = "Generated secret."
  sensitive   = true
  value       = local.secret
}

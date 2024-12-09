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
    for k, v in google_compute_router_peer.bgp_peer : k => v
  }
}

output "external_gateway" {
  description = "External VPN gateway resource."
  value       = one(google_compute_external_vpn_gateway.external_gateway[*])
}

output "gateway" {
  description = "VPN gateway resource (only if auto-created)."
  value       = one(google_compute_ha_vpn_gateway.ha_gateway[*])
}

output "id" {
  description = "Fully qualified VPN gateway id."
  value = (
    "projects/${var.project_id}/regions/${var.region}/vpnGateways/${var.name}"
  )
}

output "md5_keys" {
  description = "BGP tunnels MD5 keys."
  value = {
    for k, v in var.tunnels :
    k => try(v.bgp_peer.md5_authentication_key, null) == null ? {} : {
      key  = coalesce(v.bgp_peer.md5_authentication_key.key, local.md5_keys[k])
      name = v.bgp_peer.md5_authentication_key.name
    }
  }
}

output "name" {
  description = "VPN gateway name (only if auto-created)."
  value       = one(google_compute_ha_vpn_gateway.ha_gateway[*].name)
}

output "random_secret" {
  description = "Generated secret."
  value       = local.secret
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = one(google_compute_router.router[*])
}

output "router_name" {
  description = "Router name."
  value       = local.router
}

output "self_link" {
  description = "HA VPN gateway self link."
  value       = local.vpn_gateway
}

output "shared_secrets" {
  description = "IPSEC tunnels shared secrets."
  value = {
    for k, v in var.tunnels
    : k => coalesce(v.shared_secret, local.secret)
  }
}

output "tunnel_names" {
  description = "VPN tunnel names."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name].name, null)
  }
}

output "tunnel_self_links" {
  description = "VPN tunnel self links."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name].self_link, null)
  }
}

output "tunnels" {
  description = "VPN tunnel resources."
  value = {
    for name in keys(var.tunnels) :
    name => try(google_compute_vpn_tunnel.tunnels[name], null)
  }
}

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

locals {
  gateway_address = (
    var.create_address
    ? google_compute_address.gateway[0].address
    : var.gateway_address
  )
  router = (
    var.create_router
    ? google_compute_router.router[0].name
    : var.router_name
  )
  secret = random_id.secret.b64_url
}

resource "google_compute_address" "gateway" {
  count   = var.create_address ? 1 : 0
  name    = "vpn-${var.name}"
  project = var.project_id
  region  = var.region
}

resource "google_compute_forwarding_rule" "esp" {
  name        = "vpn-${var.name}-esp"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "ESP"
}

resource "google_compute_forwarding_rule" "udp-500" {
  name        = "vpn-${var.name}-udp-500"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "UDP"
  port_range  = "500"
}

resource "google_compute_forwarding_rule" "udp-4500" {
  name        = "vpn-${var.name}-udp-4500"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "UDP"
  port_range  = "4500"
}

resource "google_compute_router" "router" {
  count   = var.create_router ? 1 : 0
  name    = "${local.prefix}${var.router_name}"
  project = var.project_id
  region  = var.region
  network = var.router_network
  bgp {
    asn = var.router_asn
  }
}

resource "google_compute_router_peer" "bgp_peer" {
  for_each                  = var.tunnels
  region                    = var.region
  project                   = var.project_id
  name                      = "${var.name}-${each.key}"
  router                    = local.router
  peer_ip_address           = each.value.bgp_peer_address
  peer_asn                  = each.value.bgp_peer_asn
  advertised_route_priority = var.advertised_route_priority
  interface                 = google_compute_router_interface.router_interface[each.key].name
}

resource "google_compute_router_interface" "router_interface" {
  for_each   = var.tunnels
  project    = var.project_id
  region     = var.region
  name       = "${var.name}-${each.key}"
  router     = local.router
  ip_range   = length(each.value.bgp_session_range) == 0 ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_vpn_gateway" "gateway" {
  name    = var.name
  project = var.project_id
  region  = var.region
  network = var.network
}

resource "google_compute_vpn_tunnel" "tunnels" {
  for_each                = var.tunnels
  project                 = var.project_id
  region                  = var.region
  name                    = "${var.name}-${each.key}"
  router                  = local.router
  peer_ip                 = each.value.peer_ip
  local_traffic_selector  = each.value.traffic_selectors.local
  remote_traffic_selector = each.value.traffic_selectors.remote
  ike_version             = each.value.ike_version
  shared_secret           = each.value.shared_secret == "" ? local.secret : each.value.shared_secret
  target_vpn_gateway      = google_compute_vpn_gateway.gateway.self_link
}

resource "random_id" "secret" {
  byte_length = 8
}


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

locals {
  router = (
    var.router_config.create
    ? try(google_compute_router.router[0].name, null)
    : var.router_config.name
  )
  vpn_gateway = (
    var.vpn_gateway_create
    ? try(google_compute_ha_vpn_gateway.ha_gateway[0].self_link, null)
    : var.vpn_gateway
  )
  secret = random_id.secret.b64_url
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  count   = var.vpn_gateway_create ? 1 : 0
  name    = var.name
  project = var.project_id
  region  = var.region
  network = var.network
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  count           = var.peer_gateway.external != null ? 1 : 0
  name            = "external-${var.name}"
  project         = var.project_id
  redundancy_type = var.peer_gateway.external.redundancy_type
  description     = "Terraform managed external VPN gateway"
  dynamic "interface" {
    for_each = var.peer_gateway.external.interfaces
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
}

resource "google_compute_router" "router" {
  count   = var.router_config.create ? 1 : 0
  name    = coalesce(var.router_config.name, "vpn-${var.name}")
  project = var.project_id
  region  = var.region
  network = var.network
  bgp {
    advertise_mode = (
      var.router_config.custom_advertise != null
      ? "CUSTOM"
      : "DEFAULT"
    )
    advertised_groups = (
      try(var.router_config.custom_advertise.all_subnets, false)
      ? ["ALL_SUBNETS"]
      : []
    )
    dynamic "advertised_ip_ranges" {
      for_each = try(var.router_config.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = try(var.router_config.keepalive, null)
    asn                = var.router_config.asn
  }
}

resource "google_compute_router_peer" "bgp_peer" {
  for_each                  = var.tunnels
  region                    = var.region
  project                   = var.project_id
  name                      = "${var.name}-${each.key}"
  router                    = coalesce(each.value.router, local.router)
  peer_ip_address           = each.value.bgp_peer.address
  peer_asn                  = each.value.bgp_peer.asn
  advertised_route_priority = each.value.bgp_peer.route_priority
  advertise_mode = (
    try(each.value.bgp_peer.custom_advertise, null) != null
    ? "CUSTOM"
    : "DEFAULT"
  )
  advertised_groups = concat(
    try(each.value.bgp_peer.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : [],
    try(each.value.bgp_peer.custom_advertise.all_vpc_subnets, false) ? ["ALL_VPC_SUBNETS"] : [],
    try(each.value.bgp_peer.custom_advertise.all_peer_vpc_subnets, false) ? ["ALL_PEER_VPC_SUBNETS"] : []
  )
  dynamic "advertised_ip_ranges" {
    for_each = try(each.value.bgp_peer.custom_advertise.ip_ranges, {})
    iterator = range
    content {
      range       = range.key
      description = range.value
    }
  }
  interface = google_compute_router_interface.router_interface[each.key].name
}

resource "google_compute_router_interface" "router_interface" {
  for_each = var.tunnels
  project  = var.project_id
  region   = var.region
  name     = "${var.name}-${each.key}"
  router   = local.router
  # FIXME: can bgp_session_range be null?
  ip_range   = each.value.bgp_session_range == "" ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_vpn_tunnel" "tunnels" {
  for_each                        = var.tunnels
  project                         = var.project_id
  region                          = var.region
  name                            = "${var.name}-${each.key}"
  router                          = local.router
  peer_external_gateway           = one(google_compute_external_vpn_gateway.external_gateway[*].self_link)
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  peer_gcp_gateway                = var.peer_gateway.gcp
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  ike_version                     = each.value.ike_version
  shared_secret                   = coalesce(each.value.shared_secret, local.secret)
  vpn_gateway                     = local.vpn_gateway
}

resource "random_id" "secret" {
  byte_length = 8
}

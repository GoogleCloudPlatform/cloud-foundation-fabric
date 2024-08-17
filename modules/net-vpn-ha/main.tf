
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
  peer_gateways_external = {
    for k, v in var.peer_gateways : k => v.external if v.external != null
  }
  peer_gateways_gcp = {
    for k, v in var.peer_gateways : k => v.gcp if v.gcp != null
  }
  router = (
    var.router_config.create
    ? try(google_compute_router.router[0].name, null)
    : var.router_config.name
  )
  vpn_gateway = (
    var.vpn_gateway_create != null
    ? try(google_compute_ha_vpn_gateway.ha_gateway[0].self_link, null)
    : var.vpn_gateway
  )
  secret = random_id.secret.b64_url
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  count       = var.vpn_gateway_create != null ? 1 : 0
  name        = var.name
  description = var.vpn_gateway_create.description
  project     = var.project_id
  region      = var.region
  network     = var.network
  stack_type  = var.vpn_gateway_create.ipv6 ? "IPV4_IPV6" : "IPV4_ONLY"
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  for_each        = local.peer_gateways_external
  name            = each.value.name != null ? each.value.name : "${var.name}-${each.key}"
  project         = var.project_id
  redundancy_type = each.value.redundancy_type
  description     = each.value.description
  dynamic "interface" {
    for_each = each.value.interfaces
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
  name                      = each.value.bgp_peer.name != null ? each.value.bgp_peer.name : "${var.name}-${each.key}"
  router                    = coalesce(each.value.router, local.router)
  peer_ip_address           = each.value.bgp_peer.address
  peer_asn                  = each.value.bgp_peer.asn
  advertised_route_priority = each.value.bgp_peer.route_priority
  advertise_mode = (
    try(each.value.bgp_peer.custom_advertise, null) != null
    ? "CUSTOM"
    : "DEFAULT"
  )
  advertised_groups = try(each.value.bgp_peer.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
  dynamic "advertised_ip_ranges" {
    for_each = try(each.value.bgp_peer.custom_advertise.ip_ranges, {})
    iterator = range
    content {
      range       = range.key
      description = range.value
    }
  }
  dynamic "md5_authentication_key" {
    for_each = each.value.bgp_peer.md5_authentication_key != null ? toset([each.value.bgp_peer.md5_authentication_key]) : []
    content {
      name = md5_authentication_key.value.name
      key  = md5_authentication_key.value.key
    }
  }
  enable_ipv6               = try(each.value.bgp_peer.ipv6, null) == null ? false : true
  interface                 = google_compute_router_interface.router_interface[each.key].name
  ipv6_nexthop_address      = try(each.value.bgp_peer.ipv6.nexthop_address, null)
  peer_ipv6_nexthop_address = try(each.value.bgp_peer.ipv6.peer_nexthop_address, null)
}

resource "google_compute_router_interface" "router_interface" {
  for_each = var.tunnels
  project  = var.project_id
  region   = var.region
  name     = each.value.peer_router_interface_name != null ? each.value.peer_router_interface_name : "${var.name}-${each.key}"
  router   = local.router
  # FIXME: can bgp_session_range be null?
  ip_range   = each.value.bgp_session_range == "" ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_vpn_tunnel" "tunnels" {
  for_each = var.tunnels
  project  = var.project_id
  region   = var.region
  name     = each.value.name != null ? each.value.name : "${var.name}-${each.key}"
  router   = local.router
  peer_external_gateway = try(
    google_compute_external_vpn_gateway.external_gateway[each.value.peer_gateway].id,
    null
  )
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  peer_gcp_gateway = lookup(
    local.peer_gateways_gcp, each.value.peer_gateway, null
  )
  vpn_gateway_interface = each.value.vpn_gateway_interface
  ike_version           = each.value.ike_version
  shared_secret         = coalesce(each.value.shared_secret, local.secret)
  vpn_gateway           = local.vpn_gateway
}

resource "random_id" "secret" {
  byte_length = 8
}

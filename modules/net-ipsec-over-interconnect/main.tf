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

locals {
  peer_gateway_id = (
    var.peer_gateway_config.create
    ? try(google_compute_external_vpn_gateway.default[0].id, null)
    : var.peer_gateway_config.id
  )
  router = (
    var.router_config.create
    ? try(google_compute_router.default[0].name, null)
    : var.router_config.name
  )
  secret = random_id.default.b64_url

}

resource "google_compute_ha_vpn_gateway" "default" {
  name    = "vpn-gw-${var.name}"
  network = var.network
  project = var.project_id
  region  = var.region
  vpn_interfaces {
    id                      = 0
    interconnect_attachment = var.interconnect_attachments.a
  }
  vpn_interfaces {
    id                      = 1
    interconnect_attachment = var.interconnect_attachments.b
  }
}

resource "google_compute_external_vpn_gateway" "default" {
  count           = var.peer_gateway_config.create ? 1 : 0
  name            = coalesce(var.peer_gateway_config.name, "peer-vpn-gw-${var.name}")
  project         = var.project_id
  description     = var.peer_gateway_config.description
  redundancy_type = length(var.peer_gateway_config.interfaces) == 2 ? "TWO_IPS_REDUNDANCY" : "SINGLE_IP_INTERNALLY_REDUNDANT"
  dynamic "interface" {
    for_each = var.peer_gateway_config.interfaces
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
}

resource "google_compute_router" "default" {
  count   = var.router_config.create ? 1 : 0
  name    = coalesce(var.router_config.name, "router-${var.name}")
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

resource "google_compute_router_peer" "default" {
  for_each                  = var.tunnels
  region                    = var.region
  project                   = var.project_id
  name                      = "${var.name}-${each.key}"
  router                    = local.router
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
  interface = google_compute_router_interface.default[each.key].name
}

resource "google_compute_router_interface" "default" {
  for_each   = var.tunnels
  project    = var.project_id
  region     = var.region
  name       = "${var.name}-${each.key}"
  router     = local.router
  ip_range   = each.value.bgp_session_range == "" ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.default[each.key].name
}

resource "google_compute_vpn_tunnel" "default" {
  for_each                        = var.tunnels
  project                         = var.project_id
  region                          = var.region
  name                            = "${var.name}-${each.key}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.default.id
  peer_external_gateway           = local.peer_gateway_id
  shared_secret                   = coalesce(each.value.shared_secret, local.secret)
  router                          = local.router
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  peer_external_gateway_interface = each.value.peer_external_gateway_interface
  ike_version                     = each.value.ike_version
}

resource "random_id" "default" {
  byte_length = 8
}

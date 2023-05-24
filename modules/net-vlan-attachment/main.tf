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
  ipsec_enabled           = var.vpn_gateways_ip_range == null ? false : true
  interconnect_attachment = local.ipsec_enabled ? google_compute_interconnect_attachment.encrypted[0] : google_compute_interconnect_attachment.unencrypted[0]
  router = (
    var.router_config.create
    ? local.ipsec_enabled ? try(google_compute_router.encrypted[0].name, null) : try(google_compute_router.unencrypted[0].name, null)
    : var.router_config.name
  )
}

resource "google_compute_address" "default" {
  count         = local.ipsec_enabled ? 1 : 0
  project       = var.project_id
  network       = var.network
  region        = var.region
  name          = "pool-${var.name}"
  address_type  = "INTERNAL"
  purpose       = "IPSEC_INTERCONNECT"
  address       = split("/", var.vpn_gateways_ip_range)[0]
  prefix_length = split("/", var.vpn_gateways_ip_range)[1]
}

resource "google_compute_interconnect_attachment" "encrypted" {
  count                    = local.ipsec_enabled ? 1 : 0
  project                  = var.project_id
  region                   = var.region
  router                   = local.router
  name                     = var.name
  description              = var.description
  interconnect             = var.interconnect
  bandwidth                = var.bandwidth
  mtu                      = var.mtu
  candidate_subnets        = [var.bgp_cidr]
  vlan_tag8021q            = var.vlan_tag
  admin_enabled            = var.admin_enabled
  encryption               = "IPSEC"
  type                     = "DEDICATED"
  ipsec_internal_addresses = [google_compute_address.default[0].self_link]
}

resource "google_compute_interconnect_attachment" "unencrypted" {
  count             = local.ipsec_enabled ? 0 : 1
  project           = var.project_id
  region            = var.region
  router            = local.router
  name              = var.name
  description       = var.description
  interconnect      = var.interconnect
  bandwidth         = var.bandwidth
  mtu               = var.mtu
  candidate_subnets = [var.bgp_cidr]
  vlan_tag8021q     = var.vlan_tag
  admin_enabled     = var.admin_enabled
  type              = "DEDICATED"
}

resource "google_compute_router" "encrypted" {
  count                         = var.router_config.create && local.ipsec_enabled ? 1 : 0
  name                          = "${var.name}-underlay"
  network                       = var.network
  project                       = var.project_id
  region                        = var.region
  encrypted_interconnect_router = true
  bgp {
    asn = var.router_config.asn
  }
}

resource "google_compute_router" "unencrypted" {
  count   = var.router_config.create && !local.ipsec_enabled ? 1 : 0
  name    = coalesce(var.router_config.name, "underlay-${var.name}")
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

resource "google_compute_router_interface" "default" {
  project                 = var.project_id
  region                  = var.region
  name                    = "${var.name}-intf"
  router                  = local.router
  ip_range                = "${cidrhost(var.bgp_cidr, 1)}/${split("/", var.bgp_cidr)[1]}"
  interconnect_attachment = local.interconnect_attachment.name
}

resource "google_compute_router_peer" "default" {
  name                      = "${var.name}-peer"
  project                   = var.project_id
  router                    = local.router
  region                    = var.region
  peer_ip_address           = cidrhost(var.bgp_cidr, 2)
  peer_asn                  = var.peer_asn
  interface                 = "${var.name}-intf"
  advertised_route_priority = 100
  advertise_mode            = "CUSTOM"

  dynamic "advertised_ip_ranges" {
    for_each = var.ipsec_gateway_ip_ranges
    content {
      description = advertised_ip_ranges.key
      range       = advertised_ip_ranges.value
    }
  }

  bfd {
    min_receive_interval        = 1000
    min_transmit_interval       = 1000
    multiplier                  = 5
    session_initialization_mode = "ACTIVE"
  }

  depends_on = [
    google_compute_router_interface.default
  ]
}

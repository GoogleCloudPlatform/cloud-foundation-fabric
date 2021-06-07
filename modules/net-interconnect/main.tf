
/**
 * Copyright 2021 Google LLC
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
    var.router_create
    ? try(google_compute_router.router[0].name, null)
    : var.router.name
  )
  bgp_session       = "bgp-session"
  interface         = "interface"
  vlan_interconnect = try(google_compute_interconnect_attachment.interconnect_vlan_attachment.name)
}

resource "google_compute_router" "router" {
  count       = var.router_create ? 1 : 0
  project     = var.project_id
  region      = var.region
  name        = var.router.name == "" ? "router-${var.vlan_attachment.name}" : var.router.name
  description = var.router.description
  network     = var.network_name
  bgp {
    advertise_mode = (
      var.router.advertise_config == null
      ? null
      : var.router.advertise_config.mode
    )
    advertised_groups = (
      var.router.advertise_config == null ? null : (
        var.router.advertise_config.mode != "CUSTOM"
        ? null
        : var.router.advertise_config.groups
      )
    )
    dynamic "advertised_ip_ranges" {
      for_each = (
        var.router.advertise_config == null ? {} : (
          var.router.advertise_config.mode != "CUSTOM"
          ? null
          : var.router.advertise_config.ip_ranges
        )
      )
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    asn = var.router.asn
  }
}

resource "google_compute_interconnect_attachment" "interconnect_vlan_attachment" {
  project           = var.project_id
  region            = var.region
  router            = local.router
  name              = var.vlan_attachment.name
  description       = var.vlan_attachment.description
  interconnect      = var.vlan_attachment.interconnect
  bandwidth         = var.vlan_attachment.bandwidth
  vlan_tag8021q     = var.vlan_attachment.vlan_id
  candidate_subnets = var.bgp.candidate_ip_ranges
  admin_enabled     = var.vlan_attachment.admin_enabled
  provider          = google-beta
}

resource "google_compute_router_interface" "interface" {
  project                 = var.project_id
  region                  = var.region
  name                    = "${local.interface}-${var.vlan_attachment.name}"
  router                  = local.router
  ip_range                = var.bgp.bgp_session_range
  interconnect_attachment = local.vlan_interconnect
}

resource "google_compute_router_peer" "peer" {
  project                   = var.project_id
  region                    = var.region
  name                      = "${local.bgp_session}-${var.vlan_attachment.name}"
  router                    = local.router
  peer_ip_address           = var.bgp.peer_ip_address
  peer_asn                  = var.bgp.peer_asn
  advertised_route_priority = var.bgp.advertised_route_priority
  interface                 = local.vlan_interconnect
} 
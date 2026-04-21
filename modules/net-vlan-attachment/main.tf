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
  ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ipsec_enabled = var.vpn_gateways_ip_range == null ? false : true
  network       = lookup(local.ctx.networks, var.network, var.network)
  project_id    = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region        = lookup(local.ctx.locations, var.region, var.region)
  router_name   = lookup(local.ctx.routers, try(var.router_config.name, ""), try(var.router_config.name, ""))
  router = (
    var.router_config.create
    ? local.ipsec_enabled ? try(google_compute_router.encrypted[0].name, null) : try(google_compute_router.unencrypted[0].name, null)
    : local.router_name
  )
  secret = random_id.secret.b64_url
}

resource "google_compute_address" "default" {
  count         = local.ipsec_enabled ? 1 : 0
  project       = local.project_id
  network       = local.network
  region        = local.region
  name          = "pool-${var.name}"
  address_type  = "INTERNAL"
  purpose       = "IPSEC_INTERCONNECT"
  address       = split("/", var.vpn_gateways_ip_range)[0]
  prefix_length = split("/", var.vpn_gateways_ip_range)[1]
}

resource "google_compute_interconnect_attachment" "default" {
  project                              = local.project_id
  region                               = local.region
  router                               = local.router
  name                                 = var.name
  description                          = var.description
  interconnect                         = try(var.dedicated_interconnect_config.interconnect, null)
  bandwidth                            = try(var.dedicated_interconnect_config.bandwidth, null)
  mtu                                  = local.ipsec_enabled ? null : var.mtu
  candidate_subnets                    = try(var.dedicated_interconnect_config.bgp_range, null) != null ? [var.dedicated_interconnect_config.bgp_range] : null
  vlan_tag8021q                        = try(var.dedicated_interconnect_config.vlan_tag, null)
  candidate_cloud_router_ip_address    = try(var.dedicated_interconnect_config.candidate_cloud_router_ip_address, null)
  candidate_customer_router_ip_address = try(var.dedicated_interconnect_config.candidate_customer_router_ip_address, null)
  admin_enabled                        = var.admin_enabled
  encryption                           = local.ipsec_enabled ? "IPSEC" : null
  type                                 = var.dedicated_interconnect_config == null ? "PARTNER" : "DEDICATED"
  edge_availability_domain             = try(var.partner_interconnect_config.edge_availability_domain, null)
  ipsec_internal_addresses             = local.ipsec_enabled ? [google_compute_address.default[0].self_link] : null
}

resource "google_compute_router" "encrypted" {
  count                         = var.router_config.create && local.ipsec_enabled ? 1 : 0
  name                          = "${var.name}-underlay"
  network                       = local.network
  project                       = local.project_id
  region                        = local.region
  encrypted_interconnect_router = true
  bgp {
    asn            = var.router_config.asn
    advertise_mode = var.dedicated_interconnect_config == null ? "DEFAULT" : "CUSTOM"
    dynamic "advertised_ip_ranges" {
      for_each = var.dedicated_interconnect_config == null ? var.ipsec_gateway_ip_ranges : {}
      content {
        description = advertised_ip_ranges.key
        range       = advertised_ip_ranges.value
      }
    }
  }
}

resource "google_compute_router" "unencrypted" {
  count   = var.router_config.create && !local.ipsec_enabled ? 1 : 0
  name    = coalesce(local.router_name, "underlay-${var.name}")
  project = local.project_id
  region  = local.region
  network = local.network
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
  count                   = var.dedicated_interconnect_config != null ? 1 : 0
  project                 = local.project_id
  region                  = local.region
  name                    = "${var.name}-intf"
  router                  = local.router
  ip_range                = google_compute_interconnect_attachment.default.cloud_router_ip_address
  interconnect_attachment = google_compute_interconnect_attachment.default.self_link
}

resource "google_compute_router_peer" "default" {
  count                     = var.dedicated_interconnect_config != null ? 1 : 0
  name                      = "${var.name}-peer"
  project                   = local.project_id
  router                    = local.router
  region                    = local.region
  peer_ip_address           = split("/", google_compute_interconnect_attachment.default.customer_router_ip_address)[0]
  peer_asn                  = var.peer_asn
  interface                 = google_compute_router_interface.default[0].name
  advertised_route_priority = var.dedicated_interconnect_config.bgp_priority
  advertise_mode = (
    var.bgp_peer != null
    ? (try(var.bgp_peer.custom_advertise, null) != null ? "CUSTOM" : "DEFAULT")
    : "CUSTOM"
  )

  advertised_groups = (
    try(var.bgp_peer.custom_advertise.all_subnets, false)
    ? ["ALL_SUBNETS"]
    : null
  )

  export_policies = try(var.dedicated_interconnect_config.export_policies, null)
  import_policies = try(var.dedicated_interconnect_config.import_policies, null)

  dynamic "advertised_ip_ranges" {
    for_each = var.bgp_peer != null ? try(var.bgp_peer.custom_advertise.ip_ranges, {}) : var.ipsec_gateway_ip_ranges
    iterator = range
    content {
      range       = range.value
      description = range.key
    }
  }

  dynamic "custom_learned_ip_ranges" {
    for_each = try(var.bgp_peer.custom_learned_ip_ranges.ip_ranges, {})
    iterator = range
    content {
      range = range.key
    }
  }

  custom_learned_route_priority = try(
    var.bgp_peer.custom_learned_ip_ranges.route_priority,
    null
  )

  dynamic "bfd" {
    for_each = try(var.bgp_peer.bfd, null) != null ? toset([var.bgp_peer.bfd]) : []
    content {
      session_initialization_mode = bfd.value.session_initialization_mode
      min_receive_interval        = bfd.value.min_receive_interval
      min_transmit_interval       = bfd.value.min_transmit_interval
      multiplier                  = bfd.value.multiplier
    }
  }

  dynamic "md5_authentication_key" {
    for_each = (
      try(var.bgp_peer.md5_authentication_key, null) != null
      ? [var.bgp_peer.md5_authentication_key]
      : var.router_config.md5_authentication_key != null ? [var.router_config.md5_authentication_key] : []
    )
    content {
      name = md5_authentication_key.value.name
      key  = coalesce(md5_authentication_key.value.key, local.secret)
    }
  }

  depends_on = [
    google_compute_router_interface.default
  ]
}

resource "random_id" "secret" {
  byte_length = 12
}

resource "google_compute_router_route_policy" "default" {
  for_each = var.router_config.route_policies
  project  = var.project_id
  region   = var.region
  router   = local.router
  name     = each.key
  type     = each.value.type == "IMPORT" ? "ROUTE_POLICY_TYPE_IMPORT" : each.value.type == "EXPORT" ? "ROUTE_POLICY_TYPE_EXPORT" : null

  dynamic "terms" {
    for_each = try(each.value.terms, [])
    content {
      priority = terms.value.priority
      match {
        expression  = terms.value.match.expression
        title       = try(terms.value.match.title, null)
        description = try(terms.value.match.description, null)
        location    = try(terms.value.match.location, null)
      }
      actions {
        expression  = terms.value.actions.expression
        title       = try(terms.value.actions.title, null)
        description = try(terms.value.actions.description, null)
        location    = try(terms.value.actions.location, null)
      }
    }
  }

  depends_on = [
    google_compute_router.encrypted,
    google_compute_router.unencrypted,
  ]
}

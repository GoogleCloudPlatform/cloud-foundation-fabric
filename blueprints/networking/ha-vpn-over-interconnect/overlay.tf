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

resource "google_compute_router" "encrypted-interconnect-overlay-router" {
  name    = "ioic-overlay-router-${var.region}"
  project = var.project_id
  network = var.network
  region  = var.region
  bgp {
    advertise_mode = (
      var.overlay_config.gcp_bgp.custom_advertise != null
      ? "CUSTOM"
      : "DEFAULT"
    )
    advertised_groups = (
      try(var.overlay_config.gcp_bgp.custom_advertise.all_subnets, false)
      ? ["ALL_SUBNETS"]
      : []
    )
    dynamic "advertised_ip_ranges" {
      for_each = try(var.overlay_config.gcp_bgp.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = try(var.overlay_config.gcp_bgp.keepalive, null)
    asn                = var.overlay_config.gcp_bgp.asn
  }
}

resource "google_compute_external_vpn_gateway" "default" {
  name            = "peer-vpn-gateway"
  project         = var.project_id
  description     = "Peer IPSec over Interconnect VPN gateway"
  redundancy_type = length(var.overlay_config.onprem_vpn_gateway_interfaces) == 2 ? "TWO_IPS_REDUNDANCY" : "SINGLE_IP_INTERNALLY_REDUNDANT"
  dynamic "interface" {
    for_each = var.overlay_config.onprem_vpn_gateway_interfaces
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
}

module "vpngw" {
  source     = "../../../modules/net-ipsec-over-interconnect"
  for_each   = var.overlay_config.gateways
  project_id = var.project_id
  network    = var.network
  region     = var.region
  name       = "vpngw-${each.key}"
  interconnect_attachments = {
    a = module.va-a.id
    b = module.va-b.id
  }
  peer_gateway_config = {
    create = false
    id     = google_compute_external_vpn_gateway.default.id
  }
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-overlay-router.name
  }
  tunnels = each.value
}

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

resource "google_compute_router" "encrypted-interconnect-underlay-router" {
  name                          = "ioic-underlay-router-${var.region}"
  project                       = var.project_id
  network                       = var.network
  region                        = var.region
  encrypted_interconnect_router = true
  bgp {
    advertise_mode = "DEFAULT"
    asn            = var.underlay_config.gcp_bgp.asn
  }
}

module "va-a" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = var.project_id
  network     = var.network
  region      = var.region
  name        = "${var.underlay_config.attachments.a.base_name}-a"
  description = "Encrypted VLAN Attachment ${var.underlay_config.attachments.a.base_name}-a"
  peer_asn    = var.underlay_config.attachments.a.onprem_asn
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router.name
  }
  vpn_gateways_ip_range = var.underlay_config.attachments.a.vpn_gateways_ip_range
  dedicated_interconnect_config = var.underlay_config.interconnect_type != "DEDICATED" ? null : {
    bandwidth    = var.underlay_config.attachments.a.bandwidth
    bgp_range    = var.underlay_config.attachments.a.bgp_range
    interconnect = var.underlay_config.attachments.a.interconnect_self_link
    vlan_tag     = var.underlay_config.attachments.a.vlan_tag
  }
  partner_interconnect_config = var.underlay_config.interconnect_type != "PARTNER" ? null : {
    edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  }
}

module "va-b" {
  source      = "../../../modules/net-vlan-attachment"
  project_id  = var.project_id
  network     = var.network
  region      = var.region
  name        = "${var.underlay_config.attachments.a.base_name}-b"
  description = "Encrypted VLAN Attachment ${var.underlay_config.attachments.a.base_name}-b"
  peer_asn    = var.underlay_config.attachments.b.onprem_asn
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router.name
  }
  vpn_gateways_ip_range = var.underlay_config.attachments.b.vpn_gateways_ip_range
  dedicated_interconnect_config = var.underlay_config.interconnect_type != "DEDICATED" ? null : {
    bandwidth    = var.underlay_config.attachments.b.bandwidth
    bgp_range    = var.underlay_config.attachments.b.bgp_range
    interconnect = var.underlay_config.attachments.b.interconnect_self_link
    vlan_tag     = var.underlay_config.attachments.b.vlan_tag
  }
  partner_interconnect_config = var.underlay_config.interconnect_type != "PARTNER" ? null : {
    edge_availability_domain = "AVAILABILITY_DOMAIN_2"
  }
}

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
  source       = "../../../modules/net-dedicated-vlan-attachment"
  project_id   = var.project_id
  network      = var.network
  region       = var.region
  name         = "${var.underlay_config.attachments.a.base_name}-a"
  bandwidth    = var.underlay_config.attachments.a.bandwidth
  bgp_range    = var.underlay_config.attachments.a.bgp_range
  description  = "Encrypted VLAN Attachment ${var.underlay_config.attachments.a.base_name}-a"
  interconnect = var.underlay_config.attachments.a.interconnect_self_link
  peer_asn     = var.underlay_config.attachments.a.onprem_asn
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router.name
  }
  vlan_tag              = var.underlay_config.attachments.a.vlan_tag
  vpn_gateways_ip_range = var.underlay_config.attachments.a.vpn_gateways_ip_range
}

module "va-b" {
  source       = "../../../modules/net-dedicated-vlan-attachment"
  project_id   = var.project_id
  network      = var.network
  region       = var.region
  name         = "${var.underlay_config.attachments.a.base_name}-b"
  bandwidth    = var.underlay_config.attachments.b.bandwidth
  bgp_range    = var.underlay_config.attachments.b.bgp_range
  description  = "Encrypted VLAN Attachment ${var.underlay_config.attachments.a.base_name}-b"
  interconnect = var.underlay_config.attachments.b.interconnect_self_link
  peer_asn     = var.underlay_config.attachments.b.onprem_asn
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router.name
  }
  vlan_tag              = var.underlay_config.attachments.b.vlan_tag
  vpn_gateways_ip_range = var.underlay_config.attachments.b.vpn_gateways_ip_range
}

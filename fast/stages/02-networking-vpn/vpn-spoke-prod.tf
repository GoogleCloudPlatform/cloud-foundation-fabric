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

# tfdoc:file:description VPN between landing and production spoke.

# local.vpn_spoke_bgp_peer_options is defined in the dev VPN file

module "landing-to-prod-ew1-vpn" {
  source           = "../../../modules/net-vpn-ha"
  project_id       = module.landing-project.project_id
  network          = module.landing-vpc.self_link
  region           = "europe-west1"
  name             = "vpn-to-prod-ew1"
  router_create    = true
  router_name      = "landing-vpn-ew1"
  router_asn       = var.router_spoke_configs.landing-ew1.asn
  peer_gcp_gateway = module.prod-to-landing-ew1-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(
        var.vpn_spoke_configs.prod-ew1.session_range, 1 + (t * 4)
      )
      asn = var.router_spoke_configs.spoke-prod-ew1.asn
    }
    bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-ew1
    bgp_session_range = "${cidrhost(
      var.vpn_spoke_configs.prod-ew1.session_range, 2 + (t * 4)
    )}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = null
    vpn_gateway_interface           = t
    }
  }
}

module "prod-to-landing-ew1-vpn" {
  source           = "../../../modules/net-vpn-ha"
  project_id       = module.prod-spoke-project.project_id
  network          = module.prod-spoke-vpc.self_link
  region           = "europe-west1"
  name             = "vpn-to-landing-ew1"
  router_create    = true
  router_name      = "prod-spoke-vpn-ew1"
  router_asn       = var.router_spoke_configs.spoke-prod-ew1.asn
  peer_gcp_gateway = module.landing-to-prod-ew1-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(
        var.vpn_spoke_configs.prod-ew1.session_range, 2 + (t * 4)
      )
      asn = var.router_spoke_configs.landing-ew1.asn
    }
    bgp_peer_options = local.vpn_spoke_bgp_peer_options.prod-ew1
    bgp_session_range = "${cidrhost(
      var.vpn_spoke_configs.prod-ew1.session_range, 1 + (t * 4)
    )}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = module.landing-to-prod-ew1-vpn.random_secret
    vpn_gateway_interface           = t
    }
  }
}

module "landing-to-prod-ew4-vpn" {
  source           = "../../../modules/net-vpn-ha"
  project_id       = module.landing-project.project_id
  network          = module.landing-vpc.self_link
  region           = "europe-west4"
  name             = "vpn-to-prod-ew4"
  router_create    = true
  router_name      = "landing-vpn-ew4"
  router_asn       = var.router_spoke_configs.landing-ew4.asn
  peer_gcp_gateway = module.prod-to-landing-ew4-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(
        var.vpn_spoke_configs.prod-ew4.session_range, 1 + (t * 4)
      )
      asn = var.router_spoke_configs.spoke-prod-ew4.asn
    }
    bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-ew4
    bgp_session_range = "${cidrhost(
      var.vpn_spoke_configs.prod-ew4.session_range, 2 + (t * 4)
    )}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = null
    vpn_gateway_interface           = t
    }
  }
}

module "prod-to-landing-ew4-vpn" {
  source           = "../../../modules/net-vpn-ha"
  project_id       = module.prod-spoke-project.project_id
  network          = module.prod-spoke-vpc.self_link
  region           = "europe-west4"
  name             = "vpn-to-landing-ew4"
  router_create    = true
  router_name      = "prod-spoke-vpn-ew4"
  router_asn       = var.router_spoke_configs.spoke-prod-ew4.asn
  peer_gcp_gateway = module.landing-to-prod-ew4-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(
        var.vpn_spoke_configs.prod-ew4.session_range, 2 + (t * 4)
      )
      asn = var.router_spoke_configs.landing-ew4.asn
    }
    bgp_peer_options = local.vpn_spoke_bgp_peer_options.prod-ew4
    bgp_session_range = "${cidrhost(
      var.vpn_spoke_configs.prod-ew4.session_range, 1 + (t * 4)
    )}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = module.landing-to-prod-ew4-vpn.random_secret
    vpn_gateway_interface           = t
    }
  }
}

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

# tfdoc:file:description VPN between landing and development spoke.

module "landing-to-dev-ew1-vpn" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v12.0.0"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.self_link
  region     = "europe-west1"
  name       = "vpn-to-dev-ew1"
  # The router used for this VPN is managed in vpn-prod.tf
  router_create    = false
  router_name      = "landing-vpn-ew1"
  router_asn       = var.router_configs.landing-ew1.asn
  peer_gcp_gateway = module.dev-to-landing-ew1-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(var.vpn_spoke_configs.dev-ew1.session_range, 1 + (t * 4))
      asn     = var.router_configs.spoke-dev-ew1.asn
    }
    bgp_peer_options                = local.bgp_peer_options["landing-ew1"]
    bgp_session_range               = "${cidrhost(var.vpn_spoke_configs.dev-ew1.session_range, 2 + (t * 4))}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = null
    vpn_gateway_interface           = t
    }
  }
  depends_on = [
    module.landing-to-prod-ew1-vpn.router
  ]
}

module "dev-to-landing-ew1-vpn" {
  source           = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v12.0.0"
  project_id       = module.dev-spoke-project.project_id
  network          = module.dev-spoke-vpc.self_link
  region           = "europe-west1"
  name             = "vpn-to-landing-ew1"
  router_create    = true
  router_name      = "dev-spoke-vpn-ew1"
  router_asn       = var.router_configs.spoke-dev-ew1.asn
  peer_gcp_gateway = module.landing-to-dev-ew1-vpn.self_link
  tunnels = { for t in range(2) : "tunnel-${t}" => {
    bgp_peer = {
      address = cidrhost(var.vpn_spoke_configs.dev-ew1.session_range, 2 + (t * 4))
      asn     = var.router_configs.landing-ew1.asn
    }
    bgp_peer_options                = local.bgp_peer_options["dev-ew1"]
    bgp_session_range               = "${cidrhost(var.vpn_spoke_configs.dev-ew1.session_range, 1 + (t * 4))}/30"
    ike_version                     = 2
    peer_external_gateway_interface = null
    router                          = null
    shared_secret                   = module.landing-to-dev-ew1-vpn.random_secret
    vpn_gateway_interface           = t
    }
  }
}

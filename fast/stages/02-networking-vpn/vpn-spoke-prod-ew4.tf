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

# tfdoc:file:description VPN between landing and production spoke in ew4.

# local.vpn_spoke_bgp_peer_options is defined in the dev VPN file

module "landing-to-prod-ew4-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.self_link
  region     = "europe-west4"
  name       = "vpn-to-prod-ew4"
  router_config = {
    name = "landing-vpn-ew4"
    asn  = var.router_spoke_configs.landing-ew4.asn
  }
  peer_gateway = { gcp = module.prod-to-landing-ew4-vpn.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = cidrhost("169.254.0.96/27", 1)
        asn     = var.router_spoke_configs.spoke-prod-ew4.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-ew4
      bgp_session_range = "${
        cidrhost("169.254.0.96/27", 2)
      }/30"
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = cidrhost("169.254.0.96/27", 5)
        asn     = var.router_spoke_configs.spoke-prod-ew4.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-ew4
      bgp_session_range = "${
        cidrhost("169.254.0.96/27", 6)
      }/30"
      vpn_gateway_interface = 1
    }
  }
}

module "prod-to-landing-ew4-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.prod-spoke-project.project_id
  network    = module.prod-spoke-vpc.self_link
  region     = "europe-west4"
  name       = "vpn-to-landing-ew4"
  router_config = {
    name = "prod-spoke-vpn-ew4"
    asn  = var.router_spoke_configs.spoke-prod-ew4.asn
  }
  peer_gateway = { gcp = module.landing-to-prod-ew4-vpn.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = cidrhost("169.254.0.96/27", 2)
        asn     = var.router_spoke_configs.landing-ew4.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.prod-ew4
      bgp_session_range = "${
        cidrhost("169.254.0.96/27", 1)
      }/30"
      shared_secret         = module.landing-to-prod-ew4-vpn.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = cidrhost("169.254.0.96/27", 6)
        asn     = var.router_spoke_configs.landing-ew4.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.prod-ew4
      bgp_session_range = "${
        cidrhost("169.254.0.96/27", 5)
      }/30"
      shared_secret         = module.landing-to-prod-ew4-vpn.random_secret
      vpn_gateway_interface = 1
    }
  }
}

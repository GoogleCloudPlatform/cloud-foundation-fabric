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

locals {
  # define the structures used for BGP peers in the VPN resources
  vpn_spoke_bgp_peer_options = {
    for k, v in var.vpn_spoke_configs : k => v == null ? null : {
      advertise_groups = []
      advertise_ip_ranges = {
        for range in(v == null ? [] : v.custom) :
        try(var.custom_adv[range], range) => range
      }
      advertise_mode = try(v.default, false) ? "DEFAULT" : "CUSTOM"
      route_priority = null
    }
  }
}

# development spoke

moved {
  from = module.landing-to-dev-ew1-vpn
  to   = module.landing-to-dev-primary-vpn
}

module "landing-to-dev-primary-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.self_link
  region     = var.regions.primary
  name       = "vpn-to-dev-${local.region_shortnames[var.regions.primary]}"
  router_config = {
    # The router used for this VPN is managed in vpn-prod.tf
    create = false
    name   = "landing-vpn-${local.region_shortnames[var.regions.primary]}"
    asn    = var.router_spoke_configs.landing-primary.asn
  }
  peer_gateway = { gcp = module.dev-to-landing-primary-vpn.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = cidrhost("169.254.0.0/27", 1)
        asn     = var.router_spoke_configs.spoke-dev-primary.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-primary
      bgp_session_range = "${
        cidrhost("169.254.0.0/27", 2)
      }/30"
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = cidrhost("169.254.0.0/27", 5)
        asn     = var.router_spoke_configs.spoke-dev-primary.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.landing-primary
      bgp_session_range = "${
        cidrhost("169.254.0.0/27", 6)
      }/30"
      vpn_gateway_interface = 1
    }
  }
  depends_on = [
    module.landing-to-prod-primary-vpn.router
  ]
}

moved {
  from = module.dev-to-landing-ew1-vpn
  to   = module.dev-to-landing-primary-vpn
}

module "dev-to-landing-primary-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.dev-spoke-project.project_id
  network    = module.dev-spoke-vpc.self_link
  region     = var.regions.primary
  name       = "vpn-to-landing-${local.region_shortnames[var.regions.primary]}"
  router_config = {
    name = "dev-spoke-vpn-${local.region_shortnames[var.regions.primary]}"
    asn  = var.router_spoke_configs.spoke-dev-primary.asn
  }
  peer_gateway = { gcp = module.landing-to-dev-primary-vpn.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = cidrhost("169.254.0.0/27", 2)
        asn     = var.router_spoke_configs.landing-primary.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.dev-primary
      bgp_session_range = "${
        cidrhost("169.254.0.0/27", 1)
      }/30"
      shared_secret         = module.landing-to-dev-primary-vpn.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = cidrhost("169.254.0.0/27", 6)
        asn     = var.router_spoke_configs.landing-primary.asn
      }
      bgp_peer_options = local.vpn_spoke_bgp_peer_options.dev-primary
      bgp_session_range = "${
        cidrhost("169.254.0.0/27", 5)
      }/30"
      shared_secret         = module.landing-to-dev-primary-vpn.random_secret
      vpn_gateway_interface = 1
    }
  }
}

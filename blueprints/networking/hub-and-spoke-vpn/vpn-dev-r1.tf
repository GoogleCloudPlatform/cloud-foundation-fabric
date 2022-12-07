# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Landing to Development VPN for region 1.

module "landing-to-dev-vpn-r1" {
  source     = "../../../modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.landing-vpc.self_link
  region     = var.regions.r1
  name       = "${var.prefix}-lnd-to-dev-r1"
  # router is created and managed by the production VPN module
  # so we don't configure advertisements here
  router_config = {
    create = false
    name   = "${var.prefix}-lnd-vpn-r1"
    asn    = 64514
  }
  peer_gateway = { gcp = module.dev-to-landing-vpn-r1.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = var.vpn_configs.dev-r1.asn
      }
      bgp_session_range     = "169.254.2.1/30"
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.6"
        asn     = var.vpn_configs.dev-r1.asn
      }
      bgp_session_range     = "169.254.2.5/30"
      vpn_gateway_interface = 1
    }
  }
}

module "dev-to-landing-vpn-r1" {
  source     = "../../../modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.dev-vpc.self_link
  region     = var.regions.r1
  name       = "${var.prefix}-dev-to-lnd-r1"
  router_config = {
    name = "${var.prefix}-dev-vpn-r1"
    asn  = var.vpn_configs.dev-r1.asn
    custom_advertise = {
      all_subnets = false
      ip_ranges   = coalesce(var.vpn_configs.dev-r1.custom_ranges, {})
      mode        = "CUSTOM"
    }
  }
  peer_gateway = { gcp = module.landing-to-dev-vpn-r1.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.2.2/30"
      shared_secret         = module.landing-to-dev-vpn-r1.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.5"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.2.6/30"
      shared_secret         = module.landing-to-dev-vpn-r1.random_secret
      vpn_gateway_interface = 1
    }
  }
}

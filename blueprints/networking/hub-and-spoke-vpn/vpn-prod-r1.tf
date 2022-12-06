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

# tfdoc:file:description Landing to Production VPN for region 1.

module "landing-to-prod-vpn-r1" {
  source     = "../../../modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.landing-vpc.self_link
  region     = var.regions.r1
  name       = "${var.prefix}-lnd-to-prd-r1"
  router_config = {
    name = "${var.prefix}-lnd-vpn-r1"
    asn  = var.vpn_configs.land-r1.asn
    custom_advertise = {
      all_subnets = false
      ip_ranges   = coalesce(var.vpn_configs.land-r1.custom_ranges, {})
    }
  }
  peer_gateway = { gcp = module.prod-to-landing-vpn-r1.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = var.vpn_configs.prod-r1.asn
      }
      bgp_session_range     = "169.254.0.1/30"
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.0.6"
        asn     = var.vpn_configs.prod-r1.asn
      }
      bgp_session_range     = "169.254.0.5/30"
      vpn_gateway_interface = 1
    }
  }
}

module "prod-to-landing-vpn-r1" {
  source     = "../../../modules/net-vpn-ha"
  project_id = var.project_id
  network    = module.prod-vpc.self_link
  region     = var.regions.r1
  name       = "${var.prefix}-prd-to-lnd-r1"
  router_config = {
    name = "${var.prefix}-prd-vpn-r1"
    asn  = var.vpn_configs.prod-r1.asn
    # the router is managed here but shared with the dev VPN
    custom_advertise = {
      all_subnets = false
      ip_ranges   = coalesce(var.vpn_configs.prod-r1.custom_ranges, {})
    }
  }
  peer_gateway = { gcp = module.landing-to-prod-vpn-r1.self_link }
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.0.1"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.0.2/30"
      shared_secret         = module.landing-to-prod-vpn-r1.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.0.5"
        asn     = var.vpn_configs.land-r1.asn
      }
      bgp_session_range     = "169.254.0.6/30"
      shared_secret         = module.landing-to-prod-vpn-r1.random_secret
      vpn_gateway_interface = 1
    }
  }
}

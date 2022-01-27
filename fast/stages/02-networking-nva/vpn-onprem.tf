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

# tfdoc:file:description VPN between landing and onprem.

locals {
  bgp_peer_options_onprem = {
    for k, v in var.vpn_onprem_configs :
    k => var.vpn_onprem_configs[k].adv == null ? null : {
      advertise_groups = []
      advertise_ip_ranges = {
        for adv in(var.vpn_onprem_configs[k].adv == null ? [] : var.vpn_onprem_configs[k].adv.custom) :
        var.custom_adv[adv] => adv
      }
      advertise_mode = try(var.vpn_onprem_configs[k].adv.default, false) ? "DEFAULT" : "CUSTOM"
      route_priority = null
    }
  }
}

module "landing-to-onprem-vpn-ew1" {
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.landing-project.project_id
  network       = module.landing-trusted-vpc.self_link
  region        = "europe-west1"
  name          = "vpn-to-onprem-ew1"
  router_create = true
  router_name   = "landing-to-onprem-vpn-ew1"
  router_asn    = var.router_configs.onprem-landing-trusted-ew1.asn
  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [{
      id = 0
      # on-prem router ip address
      ip_address = var.vpn_onprem_configs.landing-trusted-ew1.peer.address
    }]
  }
  tunnels = { for t in range(2) : "remote-${t}" => {
    bgp_peer = {
      address = cidrhost(var.vpn_onprem_configs.landing-trusted-ew1.session_range, 1 + (t * 4))
      asn     = var.vpn_onprem_configs.landing-trusted-ew1.peer.asn
    }
    bgp_peer_options                = local.bgp_peer_options_onprem["landing-trusted-ew1"]
    bgp_session_range               = "${cidrhost(var.vpn_onprem_configs.landing-trusted-ew1.session_range, 2 + (t * 4))}/30"
    ike_version                     = 2
    peer_external_gateway_interface = 0
    router                          = null
    shared_secret                   = var.vpn_onprem_configs.landing-trusted-ew1.peer.secret_id
    vpn_gateway_interface           = t
    }
  }
}

module "landing-to-onprem-vpn-ew3" {
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.landing-project.project_id
  network       = module.landing-trusted-vpc.self_link
  region        = "europe-west3"
  name          = "vpn-to-onprem-ew3"
  router_create = true
  router_name   = "landing-to-onprem-vpn-ew3"
  router_asn    = var.router_configs.onprem-landing-trusted-ew3.asn
  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [{
      id = 0
      # on-prem router ip address
      ip_address = var.vpn_onprem_configs.landing-trusted-ew3.peer.address
    }]
  }
  tunnels = { for t in range(2) : "remote-${t}" => {
    bgp_peer = {
      address = cidrhost(var.vpn_onprem_configs.landing-trusted-ew3.session_range, 1 + (t * 4))
      asn     = var.vpn_onprem_configs.landing-trusted-ew3.peer.asn
    }
    bgp_peer_options                = local.bgp_peer_options_onprem["landing-trusted-ew3"]
    bgp_session_range               = "${cidrhost(var.vpn_onprem_configs.landing-trusted-ew3.session_range, 2 + (t * 4))}/30"
    ike_version                     = 2
    peer_external_gateway_interface = 0
    router                          = null
    shared_secret                   = var.vpn_onprem_configs.landing-trusted-ew3.peer.secret_id
    vpn_gateway_interface           = t
    }
  }
}

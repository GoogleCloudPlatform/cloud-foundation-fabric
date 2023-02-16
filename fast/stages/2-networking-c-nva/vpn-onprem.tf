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
  enable_onprem_vpn = var.vpn_onprem_configs != null
  bgp_peer_options_onprem = local.enable_onprem_vpn == false ? null : {
    for k, v in var.vpn_onprem_configs :
    k => v.adv == null ? null : {
      custom_advertise = try(v.adv.default, false) ? null : {
        all_subnets          = false
        all_vpc_subnets      = false
        all_peer_vpc_subnets = false
        ip_ranges = {
          for adv in(v.adv == null ? [] : v.adv.custom) :
          var.custom_adv[adv] => adv
        }
      }
      route_priority = null
    }
  }
}

moved {
  from = module.landing-to-onprem-ew1-vpn
  to   = module.landing-to-onprem-primary-vpn
}

module "landing-to-onprem-primary-vpn" {
  count      = local.enable_onprem_vpn ? 1 : 0
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-trusted-vpc.self_link
  region     = var.regions.primary
  name       = "vpn-to-onprem-${local.region_shortnames[var.regions.primary]}"
  router_config = {
    name = "landing-onprem-vpn-ew1"
    asn  = var.router_configs.landing-trusted-primary.asn
  }
  peer_gateway = {
    external = var.vpn_onprem_configs.landing-trusted-primary.peer_external_gateway
  }
  tunnels = {
    for t in var.vpn_onprem_configs.landing-trusted-primary.tunnels :
    "remote-${t.vpn_gateway_interface}-${t.peer_external_gateway_interface}" => {
      bgp_peer = merge(
        { address = cidrhost(t.session_range, 1), asn = t.peer_asn },
        local.bgp_peer_options_onprem.landing-trusted-primary
      )
      bgp_session_range               = "${cidrhost(t.session_range, 2)}/30"
      peer_external_gateway_interface = t.peer_external_gateway_interface
      shared_secret                   = t.secret
      vpn_gateway_interface           = t.vpn_gateway_interface
    }
  }
}

moved {
  from = module.landing-to-onprem-ew4-vpn
  to   = module.landing-to-onprem-secondary-vpn
}

module "landing-to-onprem-secondary-vpn" {
  count      = local.enable_onprem_vpn ? 1 : 0
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-trusted-vpc.self_link
  region     = var.regions.secondary
  name       = "vpn-to-onprem-${local.region_shortnames[var.regions.secondary]}"
  router_config = {
    name = "landing-onprem-vpn-ew4"
    asn  = var.router_configs.landing-trusted-secondary.asn
  }
  peer_gateway = {
    external = var.vpn_onprem_configs.landing-trusted-secondary.peer_external_gateway
  }
  tunnels = {
    for t in var.vpn_onprem_configs.landing-trusted-secondary.tunnels :
    "remote-${t.vpn_gateway_interface}-${t.peer_external_gateway_interface}" => {
      bgp_peer = merge(
        { address = cidrhost(t.session_range, 1), asn = t.peer_asn },
        local.bgp_peer_options_onprem.landing-trusted-secondary
      )
      bgp_session_range               = "${cidrhost(t.session_range, 2)}/30"
      peer_external_gateway_interface = t.peer_external_gateway_interface
      shared_secret                   = t.secret
      vpn_gateway_interface           = t.vpn_gateway_interface
    }
  }
}

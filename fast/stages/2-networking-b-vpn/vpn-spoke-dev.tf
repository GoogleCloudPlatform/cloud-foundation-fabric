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

module "dev-to-landing-primary-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.dev-spoke-project.project_id
  network    = module.dev-spoke-vpc.self_link
  region     = var.regions.primary
  name       = "to-landing-${local.region_shortnames[var.regions.primary]}"
  peer_gateways = {
    default = { gcp = module.landing-to-spokes-primary-vpn.self_link }
  }
  router_config = {
    asn              = var.vpn_configs.dev.asn
    custom_advertise = var.vpn_configs.dev.custom_advertise
  }
  tunnels = {
    0 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.dev-primary[0], 1)
        asn     = var.vpn_configs.landing.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.dev-primary[0], 2)}/30"
      shared_secret         = module.landing-to-spokes-primary-vpn.random_secret
      vpn_gateway_interface = 0
    }
    1 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.dev-primary[1], 1)
        asn     = var.vpn_configs.landing.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.dev-primary[1], 2)}/30"
      shared_secret         = module.landing-to-spokes-primary-vpn.random_secret
      vpn_gateway_interface = 1
    }
  }
}

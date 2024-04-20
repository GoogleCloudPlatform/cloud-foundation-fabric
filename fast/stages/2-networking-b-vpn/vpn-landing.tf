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

locals {
  # persistent_counter.units.values[k]
  bgp_sessions_range_0 = "169.254.250.0/25"
  bgp_sessions_range_1 = "169.254.250.128/25"
  bgp_session_ranges = {
    prod-primary = {
      0 = cidrsubnet(local.bgp_sessions_range_0, 5, 0)
      1 = cidrsubnet(local.bgp_sessions_range_1, 5, 0)
    }
    prod-secondary = {
      0 = cidrsubnet(local.bgp_sessions_range_0, 5, 1)
      1 = cidrsubnet(local.bgp_sessions_range_1, 5, 1)
    }
    dev-primary = {
      0 = cidrsubnet(local.bgp_sessions_range_0, 5, 2)
      1 = cidrsubnet(local.bgp_sessions_range_1, 5, 2)
    }
  }
}

module "landing-to-spokes-primary-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.self_link
  region     = var.regions.primary
  name       = "to-spokes-${local.region_shortnames[var.regions.primary]}"
  peer_gateways = {
    dev  = { gcp = module.dev-to-landing-primary-vpn.self_link }
    prod = { gcp = module.prod-to-landing-primary-vpn.self_link }
  }
  router_config = {
    asn              = var.vpn_configs.landing.asn
    custom_advertise = var.vpn_configs.landing.custom_advertise
  }
  tunnels = {
    dev-0 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.dev-primary[0], 2)
        asn     = var.vpn_configs.dev.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.dev-primary[0], 1)}/30"
      peer_gateway          = "dev"
      vpn_gateway_interface = 0
    }
    dev-1 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.dev-primary[1], 2)
        asn     = var.vpn_configs.dev.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.dev-primary[1], 1)}/30"
      peer_gateway          = "dev"
      vpn_gateway_interface = 1
    }
    prod-0 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.prod-primary[0], 2)
        asn     = var.vpn_configs.prod.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.prod-primary[0], 1)}/30"
      peer_gateway          = "prod"
      vpn_gateway_interface = 0
    }
    prod-1 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.prod-primary[1], 2)
        asn     = var.vpn_configs.prod.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.prod-primary[1], 1)}/30"
      peer_gateway          = "prod"
      vpn_gateway_interface = 1
    }
  }
}

module "landing-to-spokes-secondary-vpn" {
  source     = "../../../modules/net-vpn-ha"
  project_id = module.landing-project.project_id
  network    = module.landing-vpc.self_link
  region     = var.regions.secondary
  name       = "to-spokes-${local.region_shortnames[var.regions.secondary]}"
  peer_gateways = {
    prod = { gcp = module.prod-to-landing-secondary-vpn.self_link }
  }
  router_config = {
    asn              = var.vpn_configs.landing.asn
    custom_advertise = var.vpn_configs.landing.custom_advertise
  }
  tunnels = {
    prod-0 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.prod-secondary[0], 2)
        asn     = var.vpn_configs.prod.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.prod-secondary[0], 1)}/30"
      peer_gateway          = "prod"
      vpn_gateway_interface = 0
    }
    prod-1 = {
      bgp_peer = {
        address = cidrhost(local.bgp_session_ranges.prod-secondary[1], 2)
        asn     = var.vpn_configs.prod.asn
      }
      bgp_session_range     = "${cidrhost(local.bgp_session_ranges.prod-secondary[1], 1)}/30"
      peer_gateway          = "prod"
      vpn_gateway_interface = 1
    }
  }
}

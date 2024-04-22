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
  onprem_peer_gateways = {
    primary = try(
      var.vpn_onprem_primary_config.peer_external_gateways, {}
    )
    secondary = try(
      var.vpn_onprem_secondary_config.peer_external_gateways, {}
    )
  }
}

module "landing-to-onprem-primary-vpn" {
  count         = var.vpn_onprem_primary_config == null ? 0 : 1
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.landing-project.project_id
  network       = module.landing-vpc.self_link
  region        = var.regions.primary
  name          = "vpn-to-onprem-${local.region_shortnames[var.regions.primary]}"
  router_config = try(var.vpn_onprem_primary_config.router_config, {})
  peer_gateways = {
    for k, v in local.onprem_peer_gateways.primary : k => { external = v }
  }
  tunnels = try(var.vpn_onprem_primary_config.tunnels, {})
}

module "landing-to-onprem-secondary-vpn" {
  count         = var.vpn_onprem_secondary_config == null ? 0 : 1
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.landing-project.project_id
  network       = module.landing-vpc.self_link
  region        = var.regions.secondary
  name          = "vpn-to-onprem-${local.region_shortnames[var.regions.secondary]}"
  router_config = try(var.vpn_onprem_secondary_config.router_config, {})
  peer_gateways = {
    for k, v in local.onprem_peer_gateways.secondary : k => { external = v }
  }
  tunnels = try(var.vpn_onprem_secondary_config.tunnels, {})
}

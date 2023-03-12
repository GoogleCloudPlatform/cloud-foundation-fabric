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
    dev = try(
      var.vpn_onprem_dev_primary_config.peer_external_gateways, {}
    )
    prod = try(
      var.vpn_onprem_prod_primary_config.peer_external_gateways, {}
    )
  }
}

module "landing-to-onprem-dev-primary-vpn" {
  count         = var.vpn_onprem_dev_primary_config == null ? 0 : 1
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.dev-spoke-project.project_id
  network       = module.dev-spoke-vpc.self_link
  region        = var.regions.primary
  name          = "vpn-to-onprem-${local.region_shortnames[var.regions.primary]}"
  router_config = try(var.vpn_onprem_dev_primary_config.router_config, {})
  peer_gateways = {
    for k, v in local.onprem_peer_gateways.dev : k => { external = v }
  }
  tunnels = try(var.vpn_onprem_dev_primary_config.tunnels, {})
}

module "landing-to-onprem-prod-primary-vpn" {
  count         = var.vpn_onprem_prod_primary_config == null ? 0 : 1
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.prod-spoke-project.project_id
  network       = module.prod-spoke-vpc.self_link
  region        = var.regions.primary
  name          = "vpn-to-onprem-${local.region_shortnames[var.regions.primary]}"
  router_config = try(var.vpn_onprem_prod_primary_config.router_config, {})
  peer_gateways = {
    for k, v in local.onprem_peer_gateways.prod : k => { external = v }
  }
  tunnels = try(var.vpn_onprem_prod_primary_config.tunnels, {})
}

/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Peerings between landing and spokes.

resource "google_network_connectivity_hub" "default" {
  count       = local.spoke_connection == "ncc" ? 1 : 0
  name        = "hub"
  description = "Hub"
  project     = module.landing-project.project_id
  export_psc  = var.spoke_configs.ncc_configs.export_psc
}

resource "google_network_connectivity_spoke" "spoke-dev" {
  count       = local.spoke_connection == "ncc" ? 1 : 0
  name        = "dev-spoke-0"
  project     = module.dev-spoke-project.id
  location    = "global"
  description = "NCC Spoke dev"
  hub         = google_network_connectivity_hub.default[0].id
  linked_vpc_network {
    uri                   = module.dev-spoke-vpc.self_link
    exclude_export_ranges = var.spoke_configs.ncc_configs.dev.exclude_export_ranges
  }
}

resource "google_network_connectivity_spoke" "spoke-prod" {
  count       = local.spoke_connection == "ncc" ? 1 : 0
  name        = "prod-spoke-0"
  project     = module.prod-spoke-project.id
  location    = "global"
  description = "NCC Spoke prod"
  hub         = google_network_connectivity_hub.default[0].id
  linked_vpc_network {
    uri                   = module.prod-spoke-vpc.self_link
    exclude_export_ranges = var.spoke_configs.ncc_configs.prod.exclude_export_ranges
  }
}

resource "google_network_connectivity_spoke" "onprem-primary-vpn" {
  count       = local.spoke_connection == "ncc" && var.vpn_onprem_primary_config != null ? 1 : 0
  name        = "onprem-primary-vpn"
  location    = var.regions.primary
  project     = module.landing-project.project_id
  description = "Onprem primary VPN spoke"
  hub         = google_network_connectivity_hub.default[0].id
  linked_vpn_tunnels {
    site_to_site_data_transfer = false
    uris                       = [for _, v in module.landing-to-onprem-primary-vpn[0].tunnel_self_links : v]
  }
}

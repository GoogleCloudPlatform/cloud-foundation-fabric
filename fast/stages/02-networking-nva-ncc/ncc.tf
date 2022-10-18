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

locals {
  nva_regions = toset([ for config in local.nva_configs : config.region ])
}

resource "google_network_connectivity_hub" "hub" {
  name        = "prod-hub"
  description = "NCC Hub for internal multi-region connectivity."
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_spoke" "spoke_untrusted" {
  for_each    = local.nva_regions
  name        = "prod-spoke-untrusted-${each.key}"
  project     = module.landing-project.project_id
  location    = each.key
  description = "Spoke for internal connectivity - untrusted - ${each.key}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_configs :
        key => config.ip_untrusted if config.region == each.key
      }
      iterator = nva
      content {
        virtual_machine = module.nva[nva.key].self_link
        ip_address      = nva.value
      }
    }
  }
}

resource "google_network_connectivity_spoke" "spoke_trusted" {
  for_each    = local.nva_regions
  name        = "prod-spoke-trusted-${each.key}"
  project     = module.landing-project.project_id
  location    = each.key
  description = "Spoke for internal connectivity - trusted - ${each.key}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    site_to_site_data_transfer = false
    dynamic "instances" {
      for_each = {
        for key, config in local.nva_configs :
        key => config.ip_trusted if config.region == each.key
      }
      iterator = nva
      content {
        virtual_machine = module.nva[nva.key].self_link
        ip_address      = nva.value
      }
    }
  }
}

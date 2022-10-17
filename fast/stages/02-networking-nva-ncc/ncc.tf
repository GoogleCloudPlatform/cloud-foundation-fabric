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

resource "google_network_connectivity_hub" "hub" {
  name        = "prod-hub"
  description = "NCC Hub for internal multi-region connectivity."
  project     = module.landing-project.project_id
}

resource "google_network_connectivity_spoke" "spoke_untrusted" {
  for_each    = local.nvas_config
  name        = "prod-spoke-untrusted-${each.value.trigram}"
  location    = each.value.region
  description = "Spoke for internal connectivity - untrusted - ${each.value.trigram}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.nva["${each.key}"].self_link
      ip_address      = each.value.ip_untrusted
    }
    site_to_site_data_transfer = false
  }
}

resource "google_network_connectivity_spoke" "spoke_trusted" {
  for_each    = local.nvas_config
  name        = "prod-spoke-trusted-${each.value.trigram}"
  location    = each.value.region
  description = "Spoke for internal connectivity - trusted - ${each.value.trigram}"
  hub         = google_network_connectivity_hub.hub.id

  linked_router_appliance_instances {
    instances {
      virtual_machine = google_compute_instance.nva["${each.key}"].self_link
      ip_address      = each.value.ip_trusted
    }
    site_to_site_data_transfer = false
  }
}

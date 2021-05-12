/**
 * Copyright 2021 Google LLC
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

resource "google_dns_managed_zone" "peering" {
  project     = var.host_project.project_id
  name        = "${local.infra_id}-peering-zone"
  description = "Openshift peering zone for ${local.infra_id}."
  dns_name    = "${local.subdomain}."
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = data.google_compute_network.default.id
    }
  }
  peering_config {
    target_network {
      network_url = local.dummy_network
    }
  }
}

resource "google_dns_managed_zone" "internal" {
  project     = var.service_project.project_id
  name        = "${local.infra_id}-private-zone"
  description = "Openshift internal zone for ${local.infra_id}."
  dns_name    = "${local.subdomain}."
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = local.dummy_network
    }
  }
}

resource "google_dns_record_set" "dns" {
  for_each     = toset(["api", "api-int"])
  project      = var.service_project.project_id
  name         = "${each.key}.${local.subdomain}."
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_address.api.address]
}

/*
resource "google_dns_record_set" "apps" {
  count        = local.router_address == null ? 0 : 1
  project      = var.service_project.project_id
  name         = "*.apps.${var.cluster_name}.${var.domain}."
  managed_zone = google_dns_managed_zone.internal.name
  type         = "A"
  ttl          = 60
  rrdatas      = [local.router_address]
}
*/

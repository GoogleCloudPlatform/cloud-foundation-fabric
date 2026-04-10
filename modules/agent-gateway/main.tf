/**
 * Copyright 2026 Google LLC
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

resource "google_network_services_agent_gateway" "default" {
  provider    = google-beta
  project     = var.project_id
  location    = var.region
  name        = var.name
  description = var.description
  labels      = var.labels
  protocols   = var.protocols
  registries  = var.registries

  dynamic "google_managed" {
    for_each = var.is_google_managed ? [""] : []

    content {
      governed_access_path = (
        lower(var.access_path) == "ingress"
        || var.access_path == "CLIENT_TO_AGENT"
        ? "CLIENT_TO_AGENT"
        : "AGENT_TO_ANYWHERE"
      )
    }
  }

  dynamic "network_config" {
    for_each = (
      try(var.networking_config.psc_i_network_attachment_id, null) == null
      ? [] : [""]
    )

    content {
      egress {
        network_attachment = var.networking_config.psc_i_network_attachment_id
      }
    }
  }

  dynamic "self_managed" {
    for_each = var.is_google_managed ? [] : [""]

    content {
      resource_uri = var.proxy_uri
    }
  }
}

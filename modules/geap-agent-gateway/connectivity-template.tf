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

# tfdoc:file:description Agent connectivity template.

locals {
  # The module manages a template whenever a network attachment is set.
  connectivity_template_create = (
    var.networking_config.psc_i_network_attachment_id != null
  )
  # The gateway only accepts a template reference expressed with the
  # project number, so the resource id cannot be used here: it embeds
  # the project id as it was passed in.
  connectivity_template_id = (
    local.connectivity_template_create
    ? join("/", [
      "projects", local.project_number, "locations", local.location,
      "agentConnectivityTemplates",
      google_network_services_agent_connectivity_template.default[0].agent_connectivity_template_id
    ])
    : try(lookup(
      local.ctx.agent_connectivity_templates,
      var.networking_config.connectivity_template_reuse,
      var.networking_config.connectivity_template_reuse
    ), null)
  )
  project_number = (
    var.project_number != null
    ? var.project_number
    : try(data.google_project.default[0].number, null)
  )
}

data "google_project" "default" {
  provider = google-beta
  count = (
    local.connectivity_template_create && var.project_number == null ? 1 : 0
  )
  project_id = local.project_id
}

resource "google_network_services_agent_connectivity_template" "default" {
  provider = google-beta
  count    = local.connectivity_template_create ? 1 : 0
  project  = local.project_id
  location = local.location
  agent_connectivity_template_id = coalesce(
    var.networking_config.name, var.name
  )
  access_path  = local.access_path
  access_types = var.networking_config.access_types
  description  = var.networking_config.description
  labels       = var.networking_config.labels

  egress_network_config {
    network_attachment = lookup(
      local.ctx.psc_network_attachments,
      var.networking_config.psc_i_network_attachment_id,
      var.networking_config.psc_i_network_attachment_id
    )
    vpc_egress = var.networking_config.vpc_egress

    dynamic "dns_peering_config" {
      for_each = (
        var.networking_config.dns_peering_config == null ? [] : [""]
      )
      content {
        domain = var.networking_config.dns_peering_config.domain
        target_network = lookup(
          local.ctx.networks,
          var.networking_config.dns_peering_config.target_network,
          var.networking_config.dns_peering_config.target_network
        )
      }
    }
  }
}

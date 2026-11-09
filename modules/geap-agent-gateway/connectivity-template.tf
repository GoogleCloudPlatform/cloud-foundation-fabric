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

# tfdoc:file:description Agent connectivity template and TLS trust configuration.

locals {
  _trust_config_reuse = (
    var.networking_config.tls_config == null
    ? null
    : var.networking_config.tls_config.trust_config_reuse == null
    ? null
    : lookup(
      local.ctx.trust_configs,
      var.networking_config.tls_config.trust_config_reuse,
      var.networking_config.tls_config.trust_config_reuse
    )
  )
  # The module manages a template whenever a network attachment or TLS
  # trust configuration is set.
  connectivity_template_create = (
    var.networking_config.psc_i_network_attachment_id != null
    || var.networking_config.tls_config != null
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
  connectivity_template_name = coalesce(
    var.networking_config.name, var.name
  )
  project_number = (
    var.project_number != null
    ? var.project_number
    : try(data.google_project.default[0].number, null)
  )
  trust_config_create = (
    var.networking_config.tls_config == null
    ? false
    : (
      length(var.networking_config.tls_config.trust_anchors) > 0
      || length(var.networking_config.tls_config.allowlisted_certificates) > 0
    )
  )
  # Connectivity templates also require trust config references to use
  # the project number rather than the project id.
  trust_config_id = (
    local.trust_config_create
    ? join("/", [
      "projects", local.project_number, "locations", local.location,
      "trustConfigs", google_certificate_manager_trust_config.default[0].name
    ])
    : local._trust_config_reuse == null
    ? null
    : length(split("/", local._trust_config_reuse)) == 1
    ? join("/", [
      "projects", local.project_number, "locations", local.location,
      "trustConfigs", local._trust_config_reuse
    ])
    : startswith(local._trust_config_reuse, "projects/${local.project_id}/")
    ? replace(
      local._trust_config_reuse,
      "projects/${local.project_id}/",
      "projects/${local.project_number}/"
    )
    : local._trust_config_reuse
  )
}

data "google_project" "default" {
  count = (
    local.connectivity_template_create && var.project_number == null ? 1 : 0
  )
  project_id = local.project_id
}

resource "google_certificate_manager_trust_config" "default" {
  count    = local.trust_config_create ? 1 : 0
  project  = local.project_id
  location = local.location
  name = coalesce(
    var.networking_config.tls_config.name, local.connectivity_template_name
  )
  description = var.networking_config.tls_config.description
  labels      = var.networking_config.tls_config.labels

  dynamic "allowlisted_certificates" {
    for_each = var.networking_config.tls_config.allowlisted_certificates
    content {
      pem_certificate = allowlisted_certificates.value
    }
  }

  dynamic "trust_stores" {
    for_each = (
      length(var.networking_config.tls_config.trust_anchors) > 0 ? [""] : []
    )
    content {
      dynamic "intermediate_cas" {
        for_each = var.networking_config.tls_config.intermediate_cas
        content {
          pem_certificate = intermediate_cas.value
        }
      }
      dynamic "trust_anchors" {
        for_each = var.networking_config.tls_config.trust_anchors
        content {
          pem_certificate = trust_anchors.value
        }
      }
    }
  }
}

resource "google_network_services_agent_connectivity_template" "default" {
  count                          = local.connectivity_template_create ? 1 : 0
  project                        = local.project_id
  location                       = local.location
  agent_connectivity_template_id = local.connectivity_template_name
  access_path                    = local.access_path
  access_types                   = var.networking_config.access_types
  description                    = var.networking_config.description
  labels                         = var.networking_config.labels

  egress_network_config {
    network_attachment = (
      var.networking_config.psc_i_network_attachment_id == null
      ? null
      : lookup(
        local.ctx.psc_network_attachments,
        var.networking_config.psc_i_network_attachment_id,
        var.networking_config.psc_i_network_attachment_id
      )
    )
    vpc_egress = (
      var.networking_config.psc_i_network_attachment_id == null
      ? null
      : var.networking_config.vpc_egress
    )

    dynamic "dns_peering_config" {
      for_each = (
        var.networking_config.dns_peering_config == null ? [] : [""]
      )
      content {
        domains = var.networking_config.dns_peering_config.domains
        target_network = lookup(
          local.ctx.networks,
          var.networking_config.dns_peering_config.target_network,
          var.networking_config.dns_peering_config.target_network
        )
      }
    }

    dynamic "tls_config" {
      for_each = var.networking_config.tls_config == null ? [] : [""]
      content {
        additional_roots = var.networking_config.tls_config.additional_roots
        trust_config     = local.trust_config_id
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

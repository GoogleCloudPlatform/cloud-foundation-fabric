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

locals {
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  location = lookup(
    local.ctx.locations, var.region, var.region
  )
  network_attachment_id = try(lookup(
    local.ctx.psc_network_attachments,
    var.networking_config.psc_i_network_attachment_id,
    var.networking_config.psc_i_network_attachment_id
  ), null)
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
}

resource "google_network_services_agent_gateway" "default" {
  provider    = google-beta
  project     = local.project_id
  location    = local.location
  name        = var.name
  description = var.description
  labels      = var.labels
  protocols   = var.protocols
  registries  = var.registries

  dynamic "google_managed" {
    for_each = var.is_google_managed ? [""] : []

    content {
      governed_access_path = (
        try(lower(var.access_path), "") == "ingress"
        || var.access_path == "CLIENT_TO_AGENT"
        ? "CLIENT_TO_AGENT"
        : "AGENT_TO_ANYWHERE"
      )
    }
  }

  dynamic "network_config" {
    for_each = local.network_attachment_id == null ? [] : [""]

    content {
      egress {
        network_attachment = local.network_attachment_id
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

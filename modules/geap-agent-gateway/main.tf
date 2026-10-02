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
  # Registry ids end with the '/locations/{location}' segment, which
  # identifies the individual registry governed by the gateway.
  _registry_locations = compact([
    for v in coalesce(var.registries, []) :
    try(regex("/locations/([^/]+)/?$", v)[0], "")
  ])
  access_path = (
    try(lower(var.access_path), "") == "ingress"
    || var.access_path == "CLIENT_TO_AGENT"
    ? "CLIENT_TO_AGENT"
    : "AGENT_TO_ANYWHERE"
  )
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  location = lookup(
    local.ctx.locations, var.region, var.region
  )
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
  # Registry-wide bindings apply to every governed registry, and fall
  # back to the gateway region when the gateway governs none.
  registry_locations = (
    length(local._registry_locations) == 0
    ? [local.location]
    : distinct(local._registry_locations)
  )
}

resource "google_network_services_agent_gateway" "default" {
  provider                    = google-beta
  project                     = local.project_id
  location                    = local.location
  name                        = var.name
  agent_connectivity_template = local.connectivity_template_id
  description                 = var.description
  labels                      = var.labels
  registries                  = var.registries


  dynamic "google_managed" {
    for_each = var.is_google_managed ? [""] : []

    content {
      governed_access_path = local.access_path
    }
  }

  dynamic "self_managed" {
    for_each = var.is_google_managed ? [] : [""]

    content {
      resource_uri = var.proxy_uri
    }
  }
}

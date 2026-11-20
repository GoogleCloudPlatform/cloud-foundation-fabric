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
  # The spec type is derived from the presence of spec content: each
  # service type only supports NO_SPEC and the value below.
  _spec_types = {
    agent      = "A2A_AGENT_CARD"
    endpoint   = null
    mcp_server = "TOOL_SPEC"
  }
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  location = lookup(
    local.ctx.locations, var.location, var.location
  )
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
  services = {
    for k, v in var.services : k => merge(v, {
      location = (
        v.location == null
        ? local.location
        : lookup(local.ctx.locations, v.location, v.location)
      )
      spec_type = (
        v.content == null ? "NO_SPEC" : local._spec_types[v.type]
      )
    })
  }
  uri_prefix = "//agentregistry.googleapis.com/projects/${local.project_id}"
}

resource "google_agent_registry_service" "default" {
  for_each        = local.services
  project         = local.project_id
  location        = each.value.location
  service_id      = each.key
  display_name    = each.value.display_name
  description     = each.value.description
  deletion_policy = var.deletion_policy

  dynamic "interfaces" {
    for_each = each.value.spec_type == "A2A_AGENT_CARD" ? [] : [""]
    content {
      url              = each.value.url
      protocol_binding = each.value.protocol
    }
  }

  dynamic "agent_spec" {
    for_each = each.value.type == "agent" ? [""] : []
    content {
      type    = each.value.spec_type
      content = each.value.content
    }
  }

  dynamic "endpoint_spec" {
    for_each = each.value.type == "endpoint" ? [""] : []
    content {
      type = each.value.spec_type
    }
  }

  dynamic "mcp_server_spec" {
    for_each = each.value.type == "mcp_server" ? [""] : []
    content {
      type    = each.value.spec_type
      content = each.value.content
    }
  }
}

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

# tfdoc:file:description Agent Registry IAM bindings.

# Bindings on the whole Agent Registry.

resource "google_iap_agent_registry_iam_binding" "authoritative" {
  provider = google-beta
  for_each = local.registry_iam
  project  = local.project_id
  location = each.value.location
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]
}

resource "google_iap_agent_registry_iam_binding" "bindings" {
  provider = google-beta
  for_each = local.registry_iam_bindings.registry
  project  = local.project_id
  location = each.value.location
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_iap_agent_registry_iam_member" "members" {
  provider = google-beta
  for_each = local.registry_iam_bindings_additive.registry
  project  = local.project_id
  location = each.value.location
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

# Bindings on registered agents.

resource "google_iap_agent_registry_agent_iam_binding" "bindings" {
  provider = google-beta
  for_each = local.registry_iam_bindings.agent
  project  = local.project_id
  location = each.value.location
  agent_id = each.value.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_iap_agent_registry_agent_iam_member" "members" {
  provider = google-beta
  for_each = local.registry_iam_bindings_additive.agent
  project  = local.project_id
  location = each.value.location
  agent_id = each.value.id
  role     = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

# Bindings on registered endpoints.

resource "google_iap_agent_registry_endpoint_iam_binding" "bindings" {
  provider    = google-beta
  for_each    = local.registry_iam_bindings.endpoint
  project     = local.project_id
  location    = each.value.location
  endpoint_id = each.value.id
  role        = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_iap_agent_registry_endpoint_iam_member" "members" {
  provider    = google-beta
  for_each    = local.registry_iam_bindings_additive.endpoint
  project     = local.project_id
  location    = each.value.location
  endpoint_id = each.value.id
  role        = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

# Bindings on registered MCP servers.

resource "google_iap_agent_registry_mcp_server_iam_binding" "bindings" {
  provider      = google-beta
  for_each      = local.registry_iam_bindings.mcp_server
  project       = local.project_id
  location      = each.value.location
  mcp_server_id = each.value.id
  role          = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  members = [
    for v in each.value.members : lookup(local.ctx.iam_principals, v, v)
  ]

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_iap_agent_registry_mcp_server_iam_member" "members" {
  provider      = google-beta
  for_each      = local.registry_iam_bindings_additive.mcp_server
  project       = local.project_id
  location      = each.value.location
  mcp_server_id = each.value.id
  role          = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

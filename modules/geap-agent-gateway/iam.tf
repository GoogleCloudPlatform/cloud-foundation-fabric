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

locals {
  # Each registry resource type is governed by a different Terraform
  # resource, so bindings are grouped by the type of their target.
  _iam_types = ["agent", "endpoint", "mcp_server", "registry"]

  # Bindings by principal are inverted and merged into the role-keyed
  # ones, which then fan out to every registry governed by the gateway.
  _registry_iam_principal_roles = distinct(flatten(values(
    var.registry_iam_by_principals
  )))

  _registry_iam_principals = {
    for r in local._registry_iam_principal_roles : r => [
      for k, v in var.registry_iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }

  _registry_iam_roles = {
    for role in distinct(concat(
      keys(var.registry_iam), keys(local._registry_iam_principals)
    )) :
    role => concat(
      try(var.registry_iam[role], []),
      try(local._registry_iam_principals[role], [])
    )
  }

  # Keyed bindings target the whole registry, unless one of the '*_id'
  # attributes narrows them down to a single registered resource. The
  # location defaults to the gateway region.
  _registry_iam_bindings = {
    for k, v in var.registry_iam_bindings : k => merge(v, {
      id = coalesce(
        v.agent_id, v.endpoint_id, v.mcp_server_id, "registry"
      )
      location = lookup(
        local.ctx.locations,
        coalesce(v.location, var.region),
        coalesce(v.location, var.region)
      )
      type = (
        v.agent_id != null
        ? "agent"
        : (
          v.endpoint_id != null
          ? "endpoint"
          : (v.mcp_server_id != null ? "mcp_server" : "registry")
        )
      )
    })
  }

  _registry_iam_bindings_additive = {
    for k, v in var.registry_iam_bindings_additive : k => merge(v, {
      id = coalesce(
        v.agent_id, v.endpoint_id, v.mcp_server_id, "registry"
      )
      location = lookup(
        local.ctx.locations,
        coalesce(v.location, var.region),
        coalesce(v.location, var.region)
      )
      type = (
        v.agent_id != null
        ? "agent"
        : (
          v.endpoint_id != null
          ? "endpoint"
          : (v.mcp_server_id != null ? "mcp_server" : "registry")
        )
      )
    })
  }

  registry_iam = merge([
    for location in local.registry_locations : {
      for role, members in local._registry_iam_roles :
      "${location}/${role}" => {
        location = location
        members  = members
        role     = role
      }
    }
  ]...)

  registry_iam_bindings = {
    for t in local._iam_types : t => {
      for k, v in local._registry_iam_bindings : k => v if v.type == t
    }
  }

  registry_iam_bindings_additive = {
    for t in local._iam_types : t => {
      for k, v in local._registry_iam_bindings_additive :
      k => v if v.type == t
    }
  }
}

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

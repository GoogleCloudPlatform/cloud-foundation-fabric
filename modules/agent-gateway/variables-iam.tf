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

# tfdoc:file:description Agent Registry IAM variables.

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

variable "registry_iam" {
  description = "Agent Registry IAM bindings in {ROLE => [MEMBERS]} format, applied to every registry governed by the gateway."
  type        = map(list(string))
  nullable    = false
  default     = {}
}

variable "registry_iam_bindings" {
  description = "Authoritative Agent Registry IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}} format. Set at most one of the '*_id' attributes to scope the binding to a single registered resource, or none to target the whole registry. Location defaults to the gateway region. Keys are arbitrary."
  type = map(object({
    members       = list(string)
    role          = string
    agent_id      = optional(string)
    endpoint_id   = optional(string)
    location      = optional(string)
    mcp_server_id = optional(string)
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}

  validation {
    condition = alltrue([
      for k, v in var.registry_iam_bindings :
      length(compact([v.agent_id, v.endpoint_id, v.mcp_server_id])) <= 1
    ])
    error_message = "Set at most one of 'agent_id', 'endpoint_id', 'mcp_server_id'."
  }
}

variable "registry_iam_bindings_additive" {
  description = "Additive Agent Registry IAM bindings. Set at most one of the '*_id' attributes to scope the binding to a single registered resource, or none to target the whole registry. Location defaults to the gateway region. Keys are arbitrary."
  type = map(object({
    member        = string
    role          = string
    agent_id      = optional(string)
    endpoint_id   = optional(string)
    location      = optional(string)
    mcp_server_id = optional(string)
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}

  validation {
    condition = alltrue([
      for k, v in var.registry_iam_bindings_additive :
      length(compact([v.agent_id, v.endpoint_id, v.mcp_server_id])) <= 1
    ])
    error_message = "Set at most one of 'agent_id', 'endpoint_id', 'mcp_server_id'."
  }
}

variable "registry_iam_by_principals" {
  description = "Authoritative Agent Registry IAM bindings in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the 'registry_iam' variable."
  type        = map(list(string))
  nullable    = false
  default     = {}
}

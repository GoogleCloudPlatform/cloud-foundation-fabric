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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    locations   = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "deletion_policy" {
  description = "Deletion policy applied to the registered services: 'DELETE', 'PREVENT' or 'ABANDON'. Uses the provider default when null."
  type        = string
  default     = null

  validation {
    condition = (
      var.deletion_policy == null
      || contains(
        ["ABANDON", "DELETE", "PREVENT"], coalesce(var.deletion_policy, "-")
      )
    )
    error_message = "The deletion_policy can be one of the following: 'ABANDON', 'DELETE', 'PREVENT'."
  }
}

variable "location" {
  description = "Default Agent Registry location for services: 'global', a multi-region ('us', 'eu') or a region."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "The ID of the project where the Agent Registry services are created."
  type        = string
  nullable    = false
}

variable "services" {
  description = "Agent Registry services, keyed by service ID. Spec content is a JSON string or the path to a file containing it: the spec type is 'NO_SPEC' when content is null, otherwise 'A2A_AGENT_CARD' for agents and 'TOOL_SPEC' for MCP servers. Agents with an agent card have no interface, so their 'url' and 'protocol' are ignored. The protocol defaults to 'JSONRPC' for MCP servers and to 'HTTP_JSON' otherwise."
  type = map(object({
    content      = optional(string)
    description  = optional(string)
    display_name = optional(string)
    location     = optional(string)
    protocol     = optional(string)
    type         = optional(string, "endpoint")
    url          = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for k in keys(var.services) : can(regex("^[a-z0-9-]{4,63}$", k))
    ])
    error_message = "Each service id must be 4-63 characters and contain only lowercase letters, digits, and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : contains(
        ["agent", "endpoint", "mcp_server"], try(v.type, "")
      )
    ])
    error_message = "The type must be one of 'agent', 'endpoint', 'mcp_server'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : contains(
        ["GRPC", "HTTP_JSON", "JSONRPC"], v.protocol
      ) if try(v.protocol, null) != null
    ])
    error_message = "The protocol must be one of 'GRPC', 'HTTP_JSON', 'JSONRPC'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services :
      try(v.protocol, null) == null || v.protocol == "JSONRPC"
      if try(v.type, null) == "mcp_server"
    ])
    error_message = "The protocol must be 'JSONRPC' when 'type' is 'mcp_server'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services :
      try(v.content, null) != null if try(v.type, null) != "endpoint"
    ])
    error_message = "The 'content' must be set when 'type' is not 'endpoint'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services :
      try(v.content, null) == null if try(v.type, null) == "endpoint"
    ])
    error_message = "The 'content' must not be set when 'type' is 'endpoint'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : (
        try(v.content, null) == null
        || try(fileexists(pathexpand(v.content)), false)
        || can(jsondecode(v.content))
      )
    ])
    error_message = "The 'content' must be a JSON string or the path to an existing file."
  }

  validation {
    condition = alltrue([
      for k, v in var.services :
      try(v.url, null) != null if try(v.type, null) != "agent"
    ])
    error_message = "The 'url' must be set when 'type' is not 'agent'."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : try(length(v.display_name), 0) <= 63
    ])
    error_message = "The display_name of a service must be at most 63 characters."
  }
}

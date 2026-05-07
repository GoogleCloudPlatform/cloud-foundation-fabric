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

variable "access_path" {
  description = "The direction the gateway applies to: ingress (CLIENT_TO_AGENT) or egress (AGENT_TO_ANYWHERE) (if var.is_google_managed = false)."
  type        = string
  default     = null

  validation {
    condition = (
      var.is_google_managed == true
      && var.access_path == null
      ? false : true
    )
    error_message = "You must specify var.access_path if var.is_google_managed = true."
  }

  validation {
    condition = (
      var.access_path != null
      && !(
        lower(var.access_path) == "egress"
        || lower(var.access_path) == "ingress"
        || var.access_path == "CLIENT_TO_AGENT"
        || var.access_path == "AGENT_TO_ANYWHERE"
      )
      ? false : true
    )

    error_message = "access_path can be one of the following: ingress (or CLIENT_TO_AGENT), egress (or AGENT_TO_ANYWHERE)."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    locations               = optional(map(string), {})
    project_ids             = optional(map(string), {})
    psc_network_attachments = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "The description of the Agent Gateway."
  type        = string
  default     = "Terraform managed."
}

variable "is_google_managed" {
  description = "Whether the Agent Gateway is Google or self-managed."
  type        = bool
  nullable    = false
  default     = true
}

variable "labels" {
  description = "Labels to associate to the Agent Gateway."
  type        = map(string)
  default     = null
}

variable "name" {
  description = "The name of the Agent Gateway."
  type        = string
  nullable    = false
}

# Structured as object, as more arguments are coming soon
variable "networking_config" {
  description = "The Agent Gateway networking configuration."
  type = object({
    psc_i_network_attachment_id = optional(string)
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "The ID of the project where the data stores and the agents will be created."
  type        = string
  nullable    = false
}

variable "protocols" {
  description = "The protocols managed by the Agent Gateway."
  type        = list(string)
  nullable    = false
  default     = ["MCP"]

  validation {
    condition     = length(var.protocols) == 0 || (length(var.protocols) == 1 && var.protocols[0] == "MCP")
    error_message = "var.protocols can be one of the following: [], [\"MCP\"]."
  }
}

variable "proxy_uri" {
  description = "The uri of a compatible self-managed proxy (if var.is_google_managed = false)."
  type        = string
  default     = null

  validation {
    condition = (
      var.is_google_managed == false
      && var.proxy_uri == null
      ? false : true
    )
    error_message = "You must specify var.proxy_uri if var.is_google_managed = false."
  }
}

variable "region" {
  description = "The region where the agent gateway is created."
  type        = string
  nullable    = false
}

variable "registries" {
  description = "A list of Agent Registries containing the agents, MCP servers and tools governed by the Agent Gateway. Note: Currently limited to project-scoped registries Must be of format //agentregistry.googleapis.com/{version}/projects/{{project}}/locations/{{location}}."
  type        = list(string)
  default     = null
}

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
    agent_connectivity_templates = optional(map(string), {})
    condition_vars               = optional(map(map(string)), {})
    custom_roles                 = optional(map(string), {})
    iam_principals               = optional(map(string), {})
    locations                    = optional(map(string), {})
    model_armor_templates        = optional(map(string), {})
    networks                     = optional(map(string), {})
    project_ids                  = optional(map(string), {})
    psc_network_attachments      = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "The description of the Agent Gateway."
  type        = string
  default     = "Terraform managed."
}

variable "iap_config" {
  description = "Delegate request authorization to Identity-Aware Proxy, which enforces the Agent Registry IAM policies. Creates an authorization extension and the 'REQUEST_AUTHZ' policy binding it to the gateway."
  type = object({
    fail_open = optional(bool, false)
    # Null enforces the IAM policies. Set to 'DRY_RUN' to audit them.
    iam_enforcement_mode = optional(string)
    name                 = optional(string)
    # 'V2' evaluates IAM Unified Access Policies, which the
    # 'registry_iam*' variables cannot manage. See the README.
    policy_version = optional(string, "V1")
    timeout        = optional(string, "2s")
  })
  default = {}

  validation {
    condition = (
      try(var.iap_config.iam_enforcement_mode, null) == null
      || try(var.iap_config.iam_enforcement_mode, null) == "DRY_RUN"
    )
    error_message = "The iam_enforcement_mode must be 'DRY_RUN', or null to enforce the policies."
  }

  validation {
    condition = contains(
      ["V1", "V2"], try(var.iap_config.policy_version, "V1")
    )
    error_message = "The policy_version can be one of the following: 'V1', 'V2'."
  }
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

variable "model_armor_config" {
  description = "Delegate content authorization to Model Armor. Creates an authorization extension and the 'CONTENT_AUTHZ' policy binding it to the gateway. Templates are not managed here: pass their ids, either fully qualified or as short ids resolved against the gateway project and region."
  type = object({
    request_template_id  = string
    response_template_id = string
    # Restrict the traffic evaluated by Model Armor to these hosts.
    authz_hosts = optional(list(string), [])
    fail_open   = optional(bool, false)
    name        = optional(string)
    timeout     = optional(string, "2s")
  })
  default = null
}

variable "name" {
  description = "The name of the Agent Gateway."
  type        = string
  nullable    = false
}

# VPC connectivity is only exposed through agent connectivity templates:
# these attributes configure the template managed by this module, unless
# the gateway reuses an existing one.
variable "networking_config" {
  description = "The Agent Gateway networking configuration. Set 'psc_i_network_attachment_id' to manage an agent connectivity template here, or 'connectivity_template_reuse' to attach the gateway to an existing one."
  type = object({
    # Both 'PUBLIC' and 'PRIVATE' can be configured, singly or
    # together. Leaves the API default when null.
    access_types                = optional(list(string))
    connectivity_template_reuse = optional(string)
    description                 = optional(string, "Terraform managed.")
    dns_peering_config = optional(object({
      domain         = string
      target_network = string
    }))
    labels = optional(map(string))
    # Defaults to the gateway name.
    name                        = optional(string)
    psc_i_network_attachment_id = optional(string)
    vpc_egress                  = optional(string, "PRIVATE_RANGES_ONLY")
  })
  nullable = false
  default  = {}

  validation {
    condition = (
      var.networking_config.psc_i_network_attachment_id == null
      || var.networking_config.connectivity_template_reuse == null
    )
    error_message = "Specify at most one of psc_i_network_attachment_id or connectivity_template_reuse."
  }

  validation {
    condition = (
      var.networking_config.dns_peering_config == null
      || var.networking_config.psc_i_network_attachment_id != null
    )
    error_message = "The dns_peering_config attribute configures the connectivity template managed here, and needs psc_i_network_attachment_id."
  }

  validation {
    condition = (
      var.networking_config.psc_i_network_attachment_id == null
      || var.access_path != null
    )
    error_message = "You must specify var.access_path when managing a connectivity template."
  }

  validation {
    condition = contains(
      ["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"],
      coalesce(var.networking_config.vpc_egress, "ALL_TRAFFIC")
    )
    error_message = "The connectivity template vpc_egress can be one of the following: 'ALL_TRAFFIC', 'PRIVATE_RANGES_ONLY'."
  }

  validation {
    condition = length(setsubtract(
      coalesce(var.networking_config.access_types, []),
      ["PRIVATE", "PUBLIC"]
    )) == 0
    error_message = "The connectivity template access_types can only contain 'PRIVATE' and 'PUBLIC'."
  }
}


variable "project_id" {
  description = "The ID of the project where the data stores and the agents will be created."
  type        = string
  nullable    = false
}

variable "project_number" {
  description = "Project number of var.project_id. Gateways reference connectivity templates by project number: set this to avoid the additional project data source read."
  type        = string
  default     = null
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

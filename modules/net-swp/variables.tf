/**
 * Copyright 2023 Google LLC
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



variable "addresses" {
  description = "One or more IP addresses to be used for Secure Web Proxy."
  type        = list(string)
  validation {
    condition     = length(var.addresses) > 0
    error_message = "Must specify at least one IP address."
  }
}

variable "certificates" {
  description = "List of certificates to be used for Secure Web Proxy."
  type        = list(string)
}

variable "delete_swg_autogen_router_on_destroy" {
  description = "Delete automatically provisioned Cloud Router on destroy."
  type        = bool
  default     = true
}

variable "description" {
  description = "Optional description for the created resources."
  type        = string
  default     = "Managed by Terraform."
}

variable "labels" {
  description = "Resource labels."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name of the Secure Web Proxy resource."
  type        = string
}

variable "network" {
  description = "Name of the network the Secure Web Proxy is deployed into."
  type        = string
}

variable "policy_rules" {
  description = "List of policy rule definitions, default to allow action. Available keys: secure_tags, url_lists, custom. URL lists that only have values set will be created."
  type = object({
    secure_tags = optional(map(object({
      tag                    = string
      session_matcher        = optional(string)
      application_matcher    = optional(string)
      priority               = number
      action                 = optional(string, "ALLOW")
      enabled                = optional(bool, true)
      tls_inspection_enabled = optional(bool, false)
      description            = optional(string)
    })), {})

    url_lists = optional(map(object({
      url_list               = string
      values                 = optional(list(string))
      session_matcher        = optional(string)
      application_matcher    = optional(string)
      priority               = number
      action                 = optional(string, "ALLOW")
      enabled                = optional(bool, true)
      tls_inspection_enabled = optional(bool, false)
      description            = optional(string)
    })), {})

    custom = optional(map(object({
      session_matcher        = optional(string)
      application_matcher    = optional(string)
      priority               = number
      action                 = optional(string, "ALLOW")
      enabled                = optional(bool, true)
      tls_inspection_enabled = optional(bool, false)
      description            = optional(string)
    })), {})
  })
  validation {
    condition = (
      length(concat(
        [for k, v in var.policy_rules.secure_tags : v.priority],
        [for k, v in var.policy_rules.url_lists : v.priority],
      [for k, v in var.policy_rules.custom : v.priority])) ==
      length(distinct(concat(
        [for k, v in var.policy_rules.secure_tags : v.priority],
        [for k, v in var.policy_rules.url_lists : v.priority],
      [for k, v in var.policy_rules.custom : v.priority])))
    )
    error_message = "Each rule must have unique priority."
  }
  default  = {}
  nullable = false
}

variable "ports" {
  description = "Ports to use for Secure Web Proxy."
  type        = list(number)
  default     = [443]
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  type        = string
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "scope" {
  description = "Scope determines how configuration across multiple Gateway instances are merged."
  type        = string
  default     = null
}

variable "service_attachment" {
  description = "PSC service attachment configuration."
  type = object({
    nat_subnets           = list(string)
    automatic_connection  = optional(bool, false)
    consumer_accept_lists = optional(map(string), {})
    consumer_reject_lists = optional(list(string))
    description           = optional(string)
    domain_name           = optional(string)
    enable_proxy_protocol = optional(bool, false)
    reconcile_connections = optional(bool)
  })
  default = null
}

variable "subnetwork" {
  description = "Name of the subnetwork the Secure Web Proxy is deployed into."
  type        = string
}

variable "tls_inspection_config" {
  description = "TLS inspection configuration."
  type = object({
    ca_pool               = optional(string, null)
    exclude_public_ca_set = optional(bool, false)
    description           = optional(string)
  })
  default = null
}

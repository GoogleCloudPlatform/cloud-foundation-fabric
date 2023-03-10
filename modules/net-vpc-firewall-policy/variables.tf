/**
 * Copyright 2022 Google LLC
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

variable "description" {
  description = "Policy description."
  type        = string
  default     = null
}

variable "egress_rules" {
  description = "List of egress rule definitions, action can be 'allow', 'deny', 'goto_next'. The match.layer4configs map is in protocol => optional [ports] format."
  type = map(object({
    action                  = optional(string, "deny")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    priority                = optional(number, 1000)
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    match = object({
      destination_ranges = optional(list(string))
      layer4_configs     = optional(map(list(string)))
      source_ranges      = optional(list(string))
      source_tags        = optional(list(string))
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.egress_rules :
      contains(["allow", "deny", "goto_next"], v.action)
    ])
    error_message = "Action can only be one of 'allow', 'deny', 'goto_next'."
  }
}

variable "ingress_rules" {
  description = "List of ingress rule definitions, action can be 'allow', 'deny', 'goto_next'."
  type = map(object({
    action                  = optional(string, "allow")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    priority                = optional(number, 1000)
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    match = object({
      destination_ranges = optional(list(string))
      source_ranges      = optional(list(string))
      source_tags        = optional(list(string))
      layer4_configs = list(object({
        protocol = string
        ports    = optional(list(string))
      }))
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.ingress_rules :
      contains(["allow", "deny", "goto_next"], v.action)
    ])
    error_message = "Action can only be one of 'allow', 'deny', 'goto_next'."
  }
}

variable "name" {
  description = "Policy name."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Policy region. Leave null for global policy."
  type        = string
  default     = null
}

variable "target_vpcs" {
  description = "Names of the VPCS to which this policy will be attached."
  type        = list(string)
  default     = []
  nullable    = false
}

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

variable "description" {
  description = "Policy description."
  type        = string
  default     = null
}

variable "egress_rules" {
  description = "List of egress rule definitions, action can be 'allow', 'deny', 'goto_next'. The match.layer4configs map is in protocol => optional [ports] format."
  type = map(object({
    priority                = number
    action                  = optional(string, "deny")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    match = object({
      destination_ranges = optional(list(string))
      source_ranges      = optional(list(string))
      source_tags        = optional(list(string))
      layer4_configs = optional(list(object({
        protocol = optional(string, "all")
        ports    = optional(list(string))
      })), [{}])
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.egress_rules : v.match.destination_ranges != null
    ])
    error_message = "Engress rules need destination ranges."
  }
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
    priority                = number
    action                  = optional(string, "allow")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    match = object({
      destination_ranges = optional(list(string))
      source_ranges      = optional(list(string))
      source_tags        = optional(list(string))
      layer4_configs = optional(list(object({
        protocol = optional(string, "all")
        ports    = optional(list(string))
      })), [{}])
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.ingress_rules :
      v.match.source_ranges != null || v.match.source_tags != null
    ])
    error_message = "Ingress rules need source ranges or tags."
  }
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
  description = "VPC ids to which this policy will be attached, in descriptive name => self link format."
  type        = map(string)
  default     = {}
  nullable    = false
}

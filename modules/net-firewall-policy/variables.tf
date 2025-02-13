/**
 * Copyright 2024 Google LLC
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

variable "attachments" {
  description = "Ids of the resources to which this policy will be attached, in descriptive name => self link format. Specify folders or organization for hierarchical policy, VPCs for network policy."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "description" {
  description = "Policy description."
  type        = string
  default     = null
}

variable "egress_rules" {
  description = "List of egress rule definitions, action can be 'allow', 'deny', 'goto_next' or 'apply_security_profile_group'. The match.layer4configs map is in protocol => optional [ports] format."
  type = map(object({
    priority                = number
    action                  = optional(string, "deny")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    security_profile_group  = optional(string)
    target_resources        = optional(list(string))
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    tls_inspect             = optional(bool, null)
    match = object({
      address_groups       = optional(list(string))
      fqdns                = optional(list(string))
      region_codes         = optional(list(string))
      threat_intelligences = optional(list(string))
      destination_ranges   = optional(list(string))
      source_ranges        = optional(list(string))
      source_tags          = optional(list(string))
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
      for k, v in var.egress_rules :
      contains(["allow", "deny", "goto_next", "apply_security_profile_group"], v.action)
    ])
    error_message = "Action can only be one of 'allow', 'deny', 'goto_next' or 'apply_security_profile_group'."
  }
}

variable "factories_config" {
  description = "Paths to folders for the optional factories."
  type = object({
    cidr_file_path          = optional(string)
    egress_rules_file_path  = optional(string)
    ingress_rules_file_path = optional(string)
  })
  nullable = false
  default  = {}
}

variable "ingress_rules" {
  description = "List of ingress rule definitions, action can be 'allow', 'deny', 'goto_next' or 'apply_security_profile_group'."
  type = map(object({
    priority                = number
    action                  = optional(string, "allow")
    description             = optional(string)
    disabled                = optional(bool, false)
    enable_logging          = optional(bool)
    security_profile_group  = optional(string)
    target_resources        = optional(list(string))
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    tls_inspect             = optional(bool, null)
    match = object({
      address_groups       = optional(list(string))
      fqdns                = optional(list(string))
      region_codes         = optional(list(string))
      threat_intelligences = optional(list(string))
      destination_ranges   = optional(list(string))
      source_ranges        = optional(list(string))
      source_tags          = optional(list(string))
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
      contains(["allow", "deny", "goto_next", "apply_security_profile_group"], v.action)
    ])
    error_message = "Action can only be one of 'allow', 'deny', 'goto_next' or 'apply_security_profile_group'."
  }
}

variable "name" {
  description = "Policy name."
  type        = string
  nullable    = false
}

variable "parent_id" {
  description = "Parent node where the policy will be created, `folders/nnn` or `organizations/nnn` for hierarchical policy, project id for a network policy."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Policy region. Leave null for hierarchical policy, set to 'global' for a global network policy."
  type        = string
  default     = null
}

variable "security_profile_group_ids" {
  description = "The optional security groups ids to be referenced in factories."
  type        = map(string)
  nullable    = false
  default     = {}
}

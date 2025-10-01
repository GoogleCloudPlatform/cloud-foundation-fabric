/**
 * Copyright 2025 Google LLC
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

variable "allow" {
  description = "List of allow rules with protocol and optional ports."
  type = list(object({
    protocol = string
    ports    = optional(list(string))
  }))
  default = []
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    project_ids    = optional(map(string), {})
    vpc_ids        = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "deny" {
  description = "List of deny rules with protocol and optional ports."
  type = list(object({
    protocol = string
    ports    = optional(list(string))
  }))
  default = []
}

variable "description" {
  description = "Firewall rule description."
  type        = string
  default     = null
}

variable "destination_ranges" {
  description = "Destination IP ranges for EGRESS rules."
  type        = list(string)
  default     = null
}

variable "direction" {
  description = "Direction of traffic: INGRESS or EGRESS."
  type        = string
  validation {
    condition     = contains(["INGRESS", "EGRESS"], var.direction)
    error_message = "Direction must be either INGRESS or EGRESS."
  }
}

variable "disabled" {
  description = "Whether the rule is disabled."
  type        = bool
  default     = null
}

variable "enable_logging" {
  description = "Enable logging for this firewall rule."
  type        = bool
  default     = null
}

variable "log_config" {
  description = "Logging configuration."
  type = object({
    metadata        = optional(string, "INCLUDE_ALL_METADATA")
    filter_expr     = optional(string)
    metadata_fields = optional(list(string))
  })
  default = null
}

variable "name" {
  description = "Firewall rule name."
  type        = string
}

variable "network_id" {
  description = "VPC network self link. Already resolved in factory."
  type        = string
}

variable "priority" {
  description = "Rule priority (0-65535)."
  type        = number
  default     = null
}

variable "rule_create" {
  description = "Create firewall rule. Set to false to skip creation."
  type        = bool
  default     = true
}

variable "source_ranges" {
  description = "Source IP ranges for INGRESS rules."
  type        = list(string)
  default     = null
}

variable "source_service_accounts" {
  description = "Source service accounts for INGRESS rules."
  type        = list(string)
  default     = null
}

variable "source_tags" {
  description = "Source network tags for INGRESS rules."
  type        = list(string)
  default     = null
}

variable "target_service_accounts" {
  description = "Target service accounts."
  type        = list(string)
  default     = null
}

variable "target_tags" {
  description = "Target network tags."
  type        = list(string)
  default     = null
}
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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    project_ids    = optional(map(string), {})
    tag_values    = optional(map(string), {})
    vpc_ids        = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "Subnet description."
  type        = string
  default     = null
}

variable "ip_cidr_range" {
  description = "The IP CIDR range of the subnet."
  type        = string
}

variable "log_config" {
  description = "Flow log configuration. Setting this variable enables flow logging."
  type = object({
    aggregation_interval = optional(string, "INTERVAL_5_SEC")
    flow_sampling        = optional(number, 0.5)
    metadata             = optional(string, "INCLUDE_ALL_METADATA")
    metadata_fields      = optional(list(string), [])
    filter_expr          = optional(string)
  })
  default = null
}

variable "private_ipv6_google_access" {
  description = "The private IPv6 Google access type for the VMs in this subnet."
  type        = string
  default     = null
}

variable "stack_type" {
  description = "The stack type for the subnet. IPV4_ONLY, IPV4_IPV6, or IPV6_ONLY."
  type        = string
  default     = null
}

variable "ipv6_access_type" {
  description = "The access type of IPv6 address this subnet holds. EXTERNAL or INTERNAL."
  type        = string
  default     = null
}

variable "external_ipv6_prefix" {
  description = "The external IPv6 address range that is assigned to this subnetwork."
  type        = string
  default     = null
}


variable "name" {
  description = "Subnet name."
  type        = string
}

variable "network_id" {
  description = "VPC network self link or name. Supports context interpolation (e.g., $vpc_ids:dev)."
  type        = string
}

variable "private_ip_google_access" {
  description = "Enable private Google access for the subnet."
  type        = bool
  default     = true
}

variable "purpose" {
  description = "The purpose of the subnet (e.g., PRIVATE, INTERNAL_HTTPS_LOAD_BALANCER)."
  type        = string
  default     = null
}

variable "region" {
  description = "Region where the subnet will be created. Supports context interpolation."
  type        = string
}

variable "role" {
  description = "The role of the subnet when purpose is INTERNAL_HTTPS_LOAD_BALANCER (ACTIVE or BACKUP)."
  type        = string
  default     = null
}

variable "secondary_ip_ranges" {
  description = "Secondary IP ranges for the subnet (e.g., for GKE pods and services)."
  type = map(object({
    ip_cidr_range = string
  }))
  default = {}
}

variable "subnet_create" {
  description = "Create subnet. Set to false to skip subnet creation."
  type        = bool
  default     = true
}

variable "tag_bindings" {
  description = "Tag bindings for the subnet, in key => value format."
  type        = map(string)
  default     = {}
  nullable    = false
}
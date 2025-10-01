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
    project_ids    = optional(map(string), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    vpc_ids        = optional(map(string), {})
    vpc_subnet_ids     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "address" {
  description = "The static IP address. Required for PSA and IPSEC_INTERCONNECT. Optional for INTERNAL and EXTERNAL."
  type        = string
  default     = null
}

variable "address_create" {
  description = "Create address. Set to false to skip address creation."
  type        = bool
  default     = true
}

variable "address_type" {
  description = "Type of address: INTERNAL, EXTERNAL, or GLOBAL."
  type        = string
  default     = null
  validation {
    condition     = var.address_type == null || contains(["INTERNAL", "EXTERNAL", "GLOBAL"], var.address_type)
    error_message = "address_type must be one of: INTERNAL, EXTERNAL, GLOBAL."
  }
}

variable "description" {
  description = "Address description."
  type        = string
  default     = null
}

variable "ipv6" {
  description = "IPv6 configuration. Set to empty map {} for IPv6 addresses."
  type = object({
    endpoint_type = optional(string) # NETLB or VM (for EXTERNAL addresses)
  })
  default = null
}

variable "labels" {
  description = "Labels to apply to the address."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Address name."
  type        = string
}

variable "prefix_length" {
  description = "Prefix length for PSA and IPSEC_INTERCONNECT addresses."
  type        = number
  default     = null
}

variable "purpose" {
  description = "Purpose of the address: GCE_ENDPOINT, SHARED_LOADBALANCER_VIP, VPC_PEERING, IPSEC_INTERCONNECT, PRIVATE_SERVICE_CONNECT, etc."
  type        = string
  default     = null
}

variable "service_attachment" {
  description = "Service attachment configuration for PSC endpoints."
  type = object({
    psc_service_attachment_link = string
    global_access               = optional(bool)
  })
  default = null
}

variable "region" {
  description = "Region for INTERNAL or EXTERNAL addresses. Not used for GLOBAL addresses."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project ID for the address resource. Supports context interpolation (e.g., $project_ids:dev)."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC network self link. Required for PSA (VPC_PEERING) addresses. Supports context interpolation (e.g., $vpc_ids:dev)."
  type        = string
  default     = null
}

variable "vpc_subnet_id" {
  description = "Subnet self link. Required for INTERNAL addresses. Supports context interpolation (e.g., $subnet_ids:dev/subnet-1)."
  type        = string
  default     = null
}

variable "tier" {
  description = "Network tier for EXTERNAL addresses: PREMIUM or STANDARD."
  type        = string
  default     = null
  validation {
    condition     = var.tier == null || contains(["PREMIUM", "STANDARD"], var.tier)
    error_message = "tier must be PREMIUM or STANDARD."
  }
}


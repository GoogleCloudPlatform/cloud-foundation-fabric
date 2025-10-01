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
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "Route description."
  type        = string
  default     = null
}

variable "dest_range" {
  description = "The destination IP CIDR range (e.g., 0.0.0.0/0 for default route)."
  type        = string
}

variable "name" {
  description = "Route name."
  type        = string
}

variable "network_id" {
  description = "VPC network self link or name. Supports context interpolation (e.g., $vpc_ids:dev)."
  type        = string
}

variable "next_hop_gateway" {
  description = "URL to a gateway that should handle matching packets. Use 'default-internet-gateway' for default internet gateway."
  type        = string
  default     = null
}

variable "next_hop_ilb" {
  description = "The URL to a forwarding rule of type loadBalancingScheme=INTERNAL that should handle matching packets."
  type        = string
  default     = null
}

variable "next_hop_instance" {
  description = "URL to an instance that should handle matching packets."
  type        = string
  default     = null
}

variable "next_hop_instance_zone" {
  description = "The zone of the instance specified in next_hop_instance."
  type        = string
  default     = null
}

variable "next_hop_ip" {
  description = "Network IP address of an instance that should handle matching packets."
  type        = string
  default     = null
}

variable "next_hop_vpn_tunnel" {
  description = "URL to a VPN tunnel that should handle matching packets."
  type        = string
  default     = null
}

variable "priority" {
  description = "Route priority. Routes with lower values have higher priority."
  type        = number
  default     = null
}

variable "route_create" {
  description = "Create route. Set to false to skip route creation."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Network tags that the route applies to."
  type        = list(string)
  default     = null
}
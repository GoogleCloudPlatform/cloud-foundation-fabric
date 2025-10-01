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

variable "connector_create" {
  description = "Create connector. Set to false to skip connector creation."
  type        = bool
  default     = true
}

variable "ip_cidr_range" {
  description = "The range of internal addresses that are reserved for this connector. Must be a CIDR block with a /28 netmask."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Machine type of VM instances. Valid values are e2-micro, f1-micro, or e2-standard-4."
  type        = string
  default     = "e2-micro"
}

variable "max_instances" {
  description = "Maximum number of instances. Must be in range [3, 10] if specified. Mutually exclusive with max_throughput."
  type        = number
  default     = null
}

variable "max_throughput" {
  description = "Maximum throughput in Mbps. Must be in range [200, 1000] if specified. Mutually exclusive with max_instances."
  type        = number
  default     = null
}

variable "min_instances" {
  description = "Minimum number of instances. Must be in range [2, 9] if specified. Mutually exclusive with min_throughput."
  type        = number
  default     = null
}

variable "min_throughput" {
  description = "Minimum throughput in Mbps. Must be in range [200, 900] if specified. Mutually exclusive with min_instances."
  type        = number
  default     = null
}

variable "name" {
  description = "Connector name."
  type        = string
}

variable "network_id" {
  description = "VPC network self link or name. Supports context interpolation (e.g., $vpc_ids:dev). Required if subnet is not specified."
  type        = string
}

variable "region" {
  description = "Region where the connector will be created."
  type        = string
}

variable "subnet" {
  description = "Subnet name for the connector. If specified, network is derived from the subnet."
  type        = string
  default     = null
}

variable "subnet_project_id" {
  description = "Project ID of the subnet if different from the connector project."
  type        = string
  default     = null
}
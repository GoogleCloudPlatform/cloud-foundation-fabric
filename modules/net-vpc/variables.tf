/**
 * Copyright 2019 Google LLC
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

variable "auto_create_subnetworks" {
  description = "Set to true to create an auto mode subnet, defaults to custom mode."
  type        = bool
  default     = false
}

variable "description" {
  description = "An optional description of this resource (triggers recreation on change)."
  type        = string
  default     = "Terraform-managed."
}

variable "iam_roles" {
  description = "List of IAM roles keyed by subnet."
  type        = map(list(string))
  default     = null
}

variable "iam_members" {
  description = "List of IAM members keyed by subnet and role."
  type        = map(map(list(string)))
  default     = null
}

variable "log_configs" {
  description = "Map of per-subnet optional configurations for flow logs when enabled."
  type        = map(map(string))
  default     = null
}

variable "log_config_defaults" {
  description = "Default configuration for flow logs when enabled."
  type = object({
    aggregation_interval = string
    flow_sampling        = number
    metadata             = string
  })
  default = {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

variable "name" {
  description = "The name of the network being created"
  type        = string
}

variable "peering_config" {
  description = "VPC peering configuration."
  type = object({
    peer_vpc_self_link = string
    export_routes      = bool
    import_routes      = bool
  })
  default = null
}

variable "project_id" {
  description = "The ID of the project where this VPC will be created"
  type        = string
}

variable "routes" {
  description = "Network routes, keyed by name."
  type = map(object({
    dest_range    = string
    priority      = number
    tags          = list(string)
    next_hop_type = string # gateway, instance, ip, vpn_tunnel, ilb
    next_hop      = string
  }))
  default = null
}

variable "routing_mode" {
  description = "The network routing mode (default 'GLOBAL')"
  type        = string
  default     = "GLOBAL"
}

variable "shared_vpc_host" {
  description = "Enable shared VPC for this project."
  type        = bool
  default     = false
}

variable "shared_vpc_service_projects" {
  description = "Shared VPC service projects to register with this host"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "The list of subnets being created"
  type = map(object({
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = null
}

variable "subnet_descriptions" {
  description = "Optional map of subnet descriptions, keyed by subnet name."
  type        = map(string)
  default     = {}
}

variable "subnet_flow_logs" {
  description = "Optional map of boolean to control flow logs (default is disabled), keyed by subnet name."
  type        = map(bool)
  default     = {}
}

variable "subnet_private_access" {
  description = "Optional map of boolean to control private Google access (default is enabled), keyed by subnet name."
  type        = map(bool)
  default     = {}
}

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

variable "auto_create_subnetworks" {
  description = "Set to true to create an auto mode subnet, defaults to custom mode."
  type        = bool
  default     = false
}

variable "data_folder" {
  description = "An optional folder containing the subnet configurations in YaML format."
  type        = string
  default     = null
}

variable "delete_default_routes_on_create" {
  description = "Set to true to delete the default routes at creation time."
  type        = bool
  default     = false
}

variable "description" {
  description = "An optional description of this resource (triggers recreation on change)."
  type        = string
  default     = "Terraform-managed."
}

variable "dns_policy" {
  description = "DNS policy setup for the VPC."
  type = object({
    inbound = bool
    logging = bool
    outbound = object({
      private_ns = list(string)
      public_ns  = list(string)
    })
  })
  default = null
}

variable "iam" {
  description = "Subnet IAM bindings in {REGION/NAME => {ROLE => [MEMBERS]} format."
  type        = map(map(list(string)))
  default     = {}
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

variable "log_configs" {
  description = "Map keyed by subnet 'region/name' of optional configurations for flow logs when enabled."
  type        = map(map(string))
  default     = {}
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes. The minimum value for this field is 1460 and the maximum value is 1500 bytes."
  default     = null
}

variable "name" {
  description = "The name of the network being created."
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

variable "peering_create_remote_end" {
  description = "Skip creation of peering on the remote end when using peering_config."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "The ID of the project where this VPC will be created."
  type        = string
}

variable "psa_config" {
  description = "The Private Service Access configuration for Service Networking."
  type = object({
    ranges = map(string)
    routes = object({
      export = bool
      import = bool
    })
  })
  default = null
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
  default = {}
}

variable "routing_mode" {
  description = "The network routing mode (default 'GLOBAL')."
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = var.routing_mode == "GLOBAL" || var.routing_mode == "REGIONAL"
    error_message = "Routing type must be GLOBAL or REGIONAL."
  }
}

variable "shared_vpc_host" {
  description = "Enable shared VPC for this project."
  type        = bool
  default     = false
}

variable "shared_vpc_service_projects" {
  description = "Shared VPC service projects to register with this host."
  type        = list(string)
  default     = []
}

variable "subnet_descriptions" {
  description = "Optional map of subnet descriptions, keyed by subnet 'region/name'."
  type        = map(string)
  default     = {}
}

variable "subnet_flow_logs" {
  description = "Optional map of boolean to control flow logs (default is disabled), keyed by subnet 'region/name'."
  type        = map(bool)
  default     = {}
}

variable "subnet_private_access" {
  description = "Optional map of boolean to control private Google access (default is enabled), keyed by subnet 'region/name'."
  type        = map(bool)
  default     = {}
}

variable "subnets" {
  description = "List of subnets being created."
  type = list(object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = []
}

variable "subnets_proxy_only" {
  description = "List of proxy-only subnets for Regional HTTPS  or Internal HTTPS load balancers. Note: Only one proxy-only subnet for each VPC network in each region can be active."
  type = list(object({
    active        = bool
    name          = string
    ip_cidr_range = string
    region        = string
  }))
  default = []
}

variable "subnets_psc" {
  description = "List of subnets for Private Service Connect service producers."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
  }))
  default = []
}

variable "vpc_create" {
  description = "Create VPC. When set to false, uses a data source to reference existing VPC."
  type        = bool
  default     = true
}

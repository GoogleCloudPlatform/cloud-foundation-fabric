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

variable "addresses" {
  description = "Optional list of external address self links."
  type        = list(string)
  default     = []
}

variable "config_port_allocation" {
  description = "Configuration for how to assign ports to virtual machines. min_ports_per_vm and max_ports_per_vm have no effect unless enable_dynamic_port_allocation is set to 'true'."
  type = object({
    enable_endpoint_independent_mapping = optional(bool, true)
    enable_dynamic_port_allocation      = optional(bool, false)
    min_ports_per_vm                    = optional(number, 64)
    max_ports_per_vm                    = optional(number, 65536)
  })

  default = {
    enable_endpoint_independent_mapping = true
    enable_dynamic_port_allocation      = false
    min_ports_per_vm                    = 64
    max_ports_per_vm                    = 65536
  }

  validation {
    condition     = var.config_port_allocation.enable_dynamic_port_allocation ? var.config_port_allocation.enable_endpoint_independent_mapping == false : true
    error_message = "You must set enable_endpoint_independent_mapping to false to set enable_dynamic_port_allocation to true."
  }
}

variable "config_source_subnets" {
  description = "Subnetwork configuration (ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, LIST_OF_SUBNETWORKS)."
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

variable "config_timeouts" {
  description = "Timeout configurations."
  type = object({
    icmp            = number
    tcp_established = number
    tcp_transitory  = number
    udp             = number
  })
  default = {
    icmp            = 30
    tcp_established = 1200
    tcp_transitory  = 30
    udp             = 30
  }
}

variable "logging_filter" {
  description = "Enables logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the Cloud NAT resource."
  type        = string
}

variable "project_id" {
  description = "Project where resources will be created."
  type        = string
}

variable "region" {
  description = "Region where resources will be created."
  type        = string
}

variable "router_asn" {
  description = "Router ASN used for auto-created router."
  type        = number
  default     = 64514
}

variable "router_create" {
  description = "Create router."
  type        = bool
  default     = true
}

variable "router_name" {
  description = "Router name, leave blank if router will be created to use auto generated name."
  type        = string
  default     = null
}

variable "router_network" {
  description = "Name of the VPC used for auto-created router."
  type        = string
  default     = null
}

variable "subnetworks" {
  description = "Subnetworks to NAT, only used when config_source_subnets equals LIST_OF_SUBNETWORKS."
  type = list(object({
    self_link            = string,
    config_source_ranges = list(string)
    secondary_ranges     = list(string)
  }))
  default = []
}

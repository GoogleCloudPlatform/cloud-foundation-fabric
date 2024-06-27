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
    min_ports_per_vm                    = optional(number)
    max_ports_per_vm                    = optional(number, 65536)
  })
  default  = {}
  nullable = false
  validation {
    condition     = var.config_port_allocation.enable_dynamic_port_allocation ? var.config_port_allocation.enable_endpoint_independent_mapping == false : true
    error_message = "You must set enable_endpoint_independent_mapping to false to set enable_dynamic_port_allocation to true."
  }
}

variable "config_source_subnetworks" {
  description = "Subnetwork configuration."
  type = object({
    all                 = optional(bool, true)
    primary_ranges_only = optional(bool)
    subnetworks = optional(list(object({
      self_link        = string
      all_ranges       = optional(bool, true)
      primary_range    = optional(bool, false)
      secondary_ranges = optional(list(string))
    })), [])
  })
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for s in var.config_source_subnetworks.subnetworks :
      (s.all_ranges == true) != ((s.primary_range == true) || try(length(s.secondary_ranges), 0) > 0)
    ])
    error_message = "Either config_source_subnetworks.subnetworks.all_ranges is true or one of primary_range or secondary_ranges must be defined."
  }
  validation {
    condition = (
      (var.config_source_subnetworks.all == true ||
      var.config_source_subnetworks.primary_ranges_only == true) != (length(try(var.config_source_subnetworks.subnetworks, [])) > 0)
    )
    error_message = "Cannot use config_source_subnetworks.all and config_source_subnetworks.primary_ranges_only together with config_source_subnetworks.subnetworks."
  }
}

variable "config_timeouts" {
  description = "Timeout configurations."
  type = object({
    icmp            = optional(number)
    tcp_established = optional(number)
    tcp_time_wait   = optional(number)
    tcp_transitory  = optional(number)
    udp             = optional(number)
  })
  default  = {}
  nullable = false
}

variable "endpoint_types" {
  description = "Specifies the endpoint Types supported by the NAT Gateway. Supported values include: ENDPOINT_TYPE_VM, ENDPOINT_TYPE_SWG, ENDPOINT_TYPE_MANAGED_PROXY_LB."
  type        = list(string)
  default     = null
  validation {
    condition = (var.endpoint_types == null ? true : setunion([
      "ENDPOINT_TYPE_VM",
      "ENDPOINT_TYPE_SWG",
      "ENDPOINT_TYPE_MANAGED_PROXY_LB",
      ], var.endpoint_types) == toset([
      "ENDPOINT_TYPE_VM",
      "ENDPOINT_TYPE_SWG",
      "ENDPOINT_TYPE_MANAGED_PROXY_LB",
      ])
    )
    error_message = "Provide one of: ENDPOINT_TYPE_VM, ENDPOINT_TYPE_SWG or ENDPOINT_TYPE_MANAGED_PROXY_LB as endpoint_types"
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
  default     = null
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

variable "rules" {
  description = "List of rules associated with this NAT."
  type = list(object({
    description   = optional(string)
    match         = string
    source_ips    = optional(list(string))
    source_ranges = optional(list(string))
  }))
  default  = []
  nullable = false
  validation {
    condition = alltrue([
      for r in var.rules :
      r.source_ips != null || r.source_ranges != null
    ])

    error_message = "All rules must specify either source_ips or source_ranges."
  }
}

variable "type" {
  description = "Whether this Cloud NAT is used for public or private IP translation. One of 'PUBLIC' or 'PRIVATE'."
  type        = string
  default     = "PUBLIC"
  nullable    = false
  validation {
    condition     = var.type == "PUBLIC" || var.type == "PRIVATE"
    error_message = "Field type must be either PUBLIC or PRIVATE."
  }
}

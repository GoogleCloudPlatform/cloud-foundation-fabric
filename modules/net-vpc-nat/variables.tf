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
  description = "Context map containing vpc_ids, subnet_ids, router_ids for interpolation."
  type = object({
    vpc_ids = optional(map(string), {})
    vpc_subnet_ids = optional(map(string), {})
    vpc_router_ids = optional(map(string), {})
  })
  default = {
    vpc_ids    = {}
    vpc_subnet_ids = {}
    vpc_router_ids = {}
  }
  nullable = false
}

variable "name" {
  description = "Name of the Cloud NAT."
  type        = string
}

variable "vpc_router_id" {
  description = "Router name or ID. Supports context interpolation with $router_ids:."
  type        = string
}

variable "nat_create" {
  description = "Whether to create the Cloud NAT."
  type        = bool
  default     = true
  nullable    = false
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option. AUTO_ONLY or MANUAL_ONLY."
  type        = string
  default     = null
}

variable "nat_ips" {
  description = "List of self-links of NAT IPs. Required when nat_ip_allocate_option is MANUAL_ONLY."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "How NAT should be configured per Subnetwork. ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, or LIST_OF_SUBNETWORKS."
  type        = string
  default     = null
}

variable "subnetworks" {
  description = "List of subnetwork configurations when source_subnetwork_ip_ranges_to_nat is LIST_OF_SUBNETWORKS."
  type = list(object({
    name                     = string
    source_ip_ranges_to_nat  = list(string)
    secondary_ip_range_names = optional(list(string))
  }))
  default  = []
  nullable = false
}

variable "icmp_idle_timeout_sec" {
  description = "Timeout (in seconds) for ICMP connections."
  type        = number
  default     = null
}

variable "tcp_established_idle_timeout_sec" {
  description = "Timeout (in seconds) for TCP established connections."
  type        = number
  default     = null
}

variable "tcp_transitory_idle_timeout_sec" {
  description = "Timeout (in seconds) for TCP transitory connections."
  type        = number
  default     = null
}

variable "tcp_time_wait_timeout_sec" {
  description = "Timeout (in seconds) for TCP connections in TIME_WAIT state."
  type        = number
  default     = null
}

variable "udp_idle_timeout_sec" {
  description = "Timeout (in seconds) for UDP connections."
  type        = number
  default     = null
}

variable "min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM from this NAT config."
  type        = number
  default     = null
}

variable "max_ports_per_vm" {
  description = "Maximum number of ports allocated to a VM from this NAT config."
  type        = number
  default     = null
}

variable "enable_dynamic_port_allocation" {
  description = "Enable dynamic port allocation."
  type        = bool
  default     = null
}

variable "enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping."
  type        = bool
  default     = null
}

variable "log_config" {
  description = "Logging configuration for NAT."
  type = object({
    enable = bool
    filter = string
  })
  default  = null
}

variable "drain_nat_ips" {
  description = "List of self-links of NAT IPs to drain."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "rules" {
  description = "List of NAT rules."
  type = list(object({
    rule_number = number
    description = optional(string)
    match       = string
    action = optional(object({
      source_nat_active_ips    = optional(list(string))
      source_nat_drain_ips     = optional(list(string))
      source_nat_active_ranges = optional(list(string))
      source_nat_drain_ranges  = optional(list(string))
    }))
  }))
  default  = []
  nullable = false
}

variable "auto_network_tier" {
  description = "The network tier to use for automatic IP reservation."
  type        = string
  default     = null
}

variable "type" {
  description = "Type of NAT. PUBLIC or PRIVATE. Requires beta provider."
  type        = string
  default     = null
}

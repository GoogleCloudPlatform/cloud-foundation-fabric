/**
 * Copyright 2023 Google LLC
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

variable "admin_enabled" {
  description = "Whether the VLAN attachment is enabled."
  type        = bool
  default     = true
}

variable "dedicated_interconnect_config" {
  description = "Partner interconnect configuration."
  type = object({
    # Possible values @ https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_interconnect_attachment#bandwidth  
    bandwidth    = optional(string, "BPS_10G")
    bgp_range    = optional(string, "169.254.128.0/29")
    interconnect = string
    vlan_tag     = string
  })
  default = null
}

variable "description" {
  description = "VLAN attachment description."
  type        = string
}

variable "ipsec_gateway_ip_ranges" {
  description = "IPSec Gateway IP Ranges."
  type        = map(string)
  default     = {}
}

variable "mtu" {
  description = "The MTU associated to the VLAN attachment (1440 / 1500)."
  type        = number
  default     = "1500"
}

variable "name" {
  description = "The common resources name, used after resource type prefix and suffix."
  type        = string
}

variable "network" {
  description = "The VPC name to which resources are associated to."
  type        = string
}

variable "partner_interconnect_config" {
  description = "Partner interconnect configuration."
  type = object({
    edge_availability_domain = string
  })
  validation {
    condition     = var.partner_interconnect_config == null ? true : contains(["AVAILABILITY_DOMAIN_1", "AVAILABILITY_DOMAIN_2", "AVAILABILITY_DOMAIN_ANY"], var.partner_interconnect_config.edge_availability_domain)
    error_message = "The edge_availability_domain must have one of these values: AVAILABILITY_DOMAIN_1, AVAILABILITY_DOMAIN_2, AVAILABILITY_DOMAIN_ANY."
  }
  default = null
}

variable "peer_asn" {
  description = "The on-premises underlay router ASN."
  type        = string
}

variable "project_id" {
  description = "The project id where resources are created."
  type        = string
}

variable "region" {
  description = "The region where resources are created."
  type        = string
}

variable "router_config" {
  description = "Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router."
  type = object({
    create = optional(bool, true)
    asn    = optional(number, 65001)
    bfd = optional(object({
      min_receive_interval        = optional(number)
      min_transmit_interval       = optional(number)
      multiplier                  = optional(number)
      session_initialization_mode = optional(string, "ACTIVE")
    }))
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
    md5_authentication_key = optional(object({
      name = string
      key  = string
    }))
    keepalive = optional(number)
    name      = optional(string, "router")
  })
  nullable = false
}

variable "vpn_gateways_ip_range" {
  description = "The IP range (cidr notation) to be used for the GCP VPN gateways. If null IPSec over Interconnect is not enabled."
  type        = string
  default     = null
}

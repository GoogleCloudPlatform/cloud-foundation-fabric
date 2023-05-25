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

variable "bandwidth" {
  # Possible values @ https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_interconnect_attachment#bandwidth
  description = "The bandwidth assigned to the VLAN attachment (e.g. BPS_10G)."
  type        = string
  default     = "BPS_10G"
}

variable "bgp_cidr" {
  description = "The underlay link-local IP range (in CIDR notation)."
  type        = string
  default     = "169.254.0.0/30"
}

variable "description" {
  description = "VLAN attachment description."
  type        = string
}

variable "interconnect" {
  description = "The identifier of the interconnect the VLAN attachment binds to."
  type        = string
}

variable "ipsec_gateway_ip_ranges" {
  description = "IPSec Gateway IP Ranges."
  type        = map(string)
  default     = {}
}

variable "mtu" {
  description = "The MTU associated to the VLAN attachemnt (1440 / 1500)."
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
    create    = optional(bool, true)
    asn       = optional(number)
    name      = optional(string)
    keepalive = optional(number)
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
  })
  nullable = false
}

variable "vlan_tag" {
  description = "The VLAN id to be used for this VLAN attachment."
  type        = number
}

variable "vpn_gateways_ip_range" {
  description = "The IP range (cidr notation) to be used for the GCP VPN gateways. If null IPSec over Interconnect is not enabled."
  type        = string
  default     = null
}

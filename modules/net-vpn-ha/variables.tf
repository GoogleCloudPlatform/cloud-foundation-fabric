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

variable "name" {
  description = "VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources."
  type        = string
}

variable "network" {
  description = "VPC used for the gateway and routes."
  type        = string
}

variable "peer_gateway" {
  description = "Configuration of the (external or GCP) peer gateway."
  type = object({
    external = optional(object({
      redundancy_type = string
      interfaces      = list(string)
    }))
    gcp = optional(string)
  })
  nullable = false
  validation {
    condition     = (var.peer_gateway.external != null) != (var.peer_gateway.gcp != null)
    error_message = "Peer gateway configuration must define exactly one between `external` and `gcp`."
  }
}

variable "project_id" {
  description = "Project where resources will be created."
  type        = string
}

variable "region" {
  description = "Region used for resources."
  type        = string
}

variable "router_config" {
  description = "Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router."
  type = object({
    create    = optional(bool, true)
    asn       = number
    name      = optional(string)
    keepalive = optional(number)
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
  })
  nullable = false
}

variable "tunnels" {
  description = "VPN tunnel configurations."
  type = map(object({
    bgp_peer = object({
      address        = string
      asn            = number
      route_priority = optional(number, 1000)
      custom_advertise = optional(object({
        all_subnets          = bool
        all_vpc_subnets      = bool
        all_peer_vpc_subnets = bool
        ip_ranges            = map(string)
      }))
    })
    # each BGP session on the same Cloud Router must use a unique /30 CIDR
    # from the 169.254.0.0/16 block.
    bgp_session_range               = string
    ike_version                     = optional(number, 2)
    peer_external_gateway_interface = optional(number)
    router                          = optional(string)
    shared_secret                   = optional(string)
    vpn_gateway_interface           = number
  }))
  default  = {}
  nullable = false
}

variable "vpn_gateway" {
  description = "HA VPN Gateway Self Link for using an existing HA VPN Gateway. Ignored if `vpn_gateway_create` is set to `true`."
  type        = string
  default     = null
}

variable "vpn_gateway_create" {
  description = "Create HA VPN Gateway."
  type        = bool
  default     = true
}

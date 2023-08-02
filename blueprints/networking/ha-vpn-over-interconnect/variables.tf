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


variable "network" {
  description = "The VPC name to which resources are associated to."
  type        = string
}


variable "overlay_config" {
  description = "Configuration for the overlay resources."
  type = object({
    gcp_bgp = object({
      asn       = number
      name      = optional(string)
      keepalive = optional(number)
      custom_advertise = optional(object({
        all_subnets = bool
        ip_ranges   = map(string)
      }))
    })
    onprem_vpn_gateway_interfaces = list(string)
    gateways = map(map(object({
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
      peer_gateway                    = optional(string, "default")
      router                          = optional(string)
      shared_secret                   = optional(string)
      vpn_gateway_interface           = number
      }))
    )
  })
}

variable "project_id" {
  description = "The project id."
  type        = string
}

variable "region" {
  description = "GCP Region."
  type        = string
}

variable "underlay_config" {
  description = "Configuration for the underlay resources."
  type = object({
    attachments = map(object({
      bandwidth              = optional(string, "BPS_10G")
      base_name              = optional(string, "encrypted-vlan-attachment")
      bgp_range              = string
      interconnect_self_link = string
      onprem_asn             = number
      vlan_tag               = number
      vpn_gateways_ip_range  = string
    }))
    gcp_bgp = object({
      asn = number
    })
    interconnect_type = optional(string, "DEDICATED")
  })
  validation {
    condition     = var.underlay_config.interconnect_type == "DEDICATED" || var.underlay_config.interconnect_type == "PARTNER"
    error_message = "var.underlay_config.interconnect_type must by either \"DEDICATED\" or \"PARTNER\""
  }
}

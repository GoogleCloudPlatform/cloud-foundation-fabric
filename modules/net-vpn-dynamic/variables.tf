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

variable "gateway_address" {
  description = "Optional address assigned to the VPN gateway. Ignored unless gateway_address_create is set to false."
  type        = string
  default     = null
}

variable "gateway_address_create" {
  description = "Create external address assigned to the VPN gateway. Needs to be explicitly set to false to use address in gateway_address variable."
  type        = bool
  default     = true
}

variable "name" {
  description = "VPN gateway name, and prefix used for dependent resources."
  type        = string
}

variable "network" {
  description = "VPC used for the gateway and routes."
  type        = string
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
    create = optional(bool, true)
    asn    = number
    name   = optional(string)
    route_policies = optional(map(object({
      type = string
      terms = list(object({
        priority = number
        match = optional(object({
          expression  = string
          title       = optional(string)
          description = optional(string)
          location    = optional(string)
        }))
        actions = optional(object({
          expression  = string
          title       = optional(string)
          description = optional(string)
          location    = optional(string)
        }))
      }))
    })), {})
    keepalive = optional(number)
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
  })
  nullable = false

  validation {
    condition = alltrue(flatten([
      for k, v in var.router_config.route_policies : [
        for t in v.terms :
        t.priority >= 0 && t.priority < 231
      ]
    ]))
    error_message = "Route policy term priority must be between 0 (inclusive) and 231 (exclusive)."
  }

  validation {
    condition = alltrue([
      for k, v in var.router_config.route_policies :
      length(v.terms) == length(distinct([for t in v.terms : t.priority]))
    ])
    error_message = "Route policy term priority must be unique within the policy."
  }

  validation {
    condition = alltrue([
      for k, v in var.router_config.route_policies :
      contains(["IMPORT", "EXPORT"], v.type)
    ])
    error_message = "Route policy type must be IMPORT or EXPORT."
  }
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
    bgp_session_range = string
    cipher_suite = optional(object({
      phase1 = optional(object({
        dh         = optional(list(string))
        encryption = optional(list(string))
        integrity  = optional(list(string))
        prf        = optional(list(string))
      }))
      phase2 = optional(object({
        encryption = optional(list(string))
        integrity  = optional(list(string))
        pfs        = optional(list(string))
      }))
    }))
    ike_version   = optional(number, 2)
    peer_ip       = string
    router        = optional(string)
    shared_secret = optional(string)
  }))
  default  = {}
  nullable = false
}

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

variable "interconnect_attachments" {
  description = "VLAN attachments used by the VPN Gateway."
  type = object({
    a = string
    b = string
  })
}

variable "name" {
  description = "Common name to identify the VPN Gateway."
  type        = string
}

variable "network" {
  description = "The VPC name to which resources are associated to."
  type        = string
}

variable "peer_gateway_config" {
  description = "IP addresses for the external peer gateway."
  type = object({
    create      = optional(bool, false)
    description = optional(string, "Terraform managed IPSec over Interconnect VPN gateway")
    name        = optional(string, null)
    id          = optional(string, null)
    interfaces  = optional(list(string), [])
  })
  nullable = false
  validation {
    condition = anytrue([
      var.peer_gateway_config.create == false && var.peer_gateway_config.id != null,
      var.peer_gateway_config.create == true && (try(length(var.peer_gateway_config.interfaces) == 1, false) || try(length(var.peer_gateway_config.interfaces) == 2, false))
    ])
    error_message = "When using an existing gateway, an ID must be provided. When not, the gateway can have one or two interfaces."
  }
}

variable "project_id" {
  description = "The project id."
  type        = string
}

variable "region" {
  description = "GCP Region."
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
      address = string
      asn     = number
      custom_advertise = optional(object({
        all_subnets          = bool
        all_vpc_subnets      = bool
        all_peer_vpc_subnets = bool
        ip_ranges            = map(string)
      }))
      md5_authentication_key = optional(object({
        name = string
        key  = string
      }))
      export_policies = optional(list(string))
      import_policies = optional(list(string))
      route_priority  = optional(number, 1000)
    })
    # each BGP session on the same Cloud Router must use a unique /30 CIDR
    # from the 169.254.0.0/16 block.
    bgp_session_range               = string
    ike_version                     = optional(number, 2)
    peer_external_gateway_interface = optional(number)
    peer_gateway_id                 = optional(string, "default")
    router                          = optional(string)
    shared_secret                   = optional(string)
    vpn_gateway_interface           = number
  }))
  default  = {}
  nullable = false
}

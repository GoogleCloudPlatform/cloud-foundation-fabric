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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    addresses    = optional(map(string), {})
    locations    = optional(map(string), {})
    networks     = optional(map(string), {})
    project_ids  = optional(map(string), {})
    routers      = optional(map(string), {})
    vpn_gateways = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "name" {
  description = "VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources."
  type        = string
}

variable "network" {
  description = "VPC used for the gateway and routes."
  type        = string
}

variable "peer_gateways" {
  description = "Configuration of the (external or GCP) peer gateway."
  type = map(object({
    external = optional(object({
      redundancy_type = string
      interfaces      = list(string)
      description     = optional(string, "Terraform managed external VPN gateway")
      name            = optional(string)
    }))
    gcp = optional(string)
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.peer_gateways : (v.external != null) != (v.gcp != null)
    ])
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
    asn    = optional(number)
    create = optional(bool, true)
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
    keepalive     = optional(number)
    name          = optional(string)
    override_name = optional(string)
  })
  nullable = false
  validation {
    condition = alltrue(flatten([
      for k, v in var.router_config.route_policies : [
        for t in v.terms :
        t.priority >= 0 && t.priority < 231
      ]
      ])) && alltrue([
      for k, v in var.router_config.route_policies :
      length(v.terms) == length(distinct([for t in v.terms : t.priority]))
    ])
    error_message = "Route policy term priority must be between 0 (inclusive) and 231 (exclusive) and unique within the policy."
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
        all_subnets = bool
        ip_ranges   = map(string)
      }))
      custom_learned_ip_ranges = optional(object({
        route_priority = optional(number, 1000)
        ip_ranges      = map(string)
      }))
      md5_authentication_key = optional(object({
        name = string
        key  = optional(string)
      }))
      export_policies = optional(list(string))
      import_policies = optional(list(string))
      ipv6 = optional(object({
        nexthop_address      = optional(string)
        peer_nexthop_address = optional(string)
      }))
      name = optional(string)
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
    ike_version                     = optional(number, 2)
    name                            = optional(string)
    peer_external_gateway_interface = optional(number)
    peer_router_interface_name      = optional(string)
    peer_gateway                    = optional(string, "default")
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
  description = "Create HA VPN Gateway. Set to null to avoid creation."
  type = object({
    description = optional(string, "Terraform managed external VPN gateway")
    ipv6        = optional(bool, false)
  })
  default = {}
}

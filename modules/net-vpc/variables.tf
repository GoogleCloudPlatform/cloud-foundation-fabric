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

variable "auto_create_subnetworks" {
  description = "Set to true to create an auto mode subnet, defaults to custom mode."
  type        = bool
  default     = false
}

variable "create_googleapis_routes" {
  description = "Toggle creation of googleapis private/restricted routes. Disabled when vpc creation is turned off, or when set to null."
  type = object({
    private      = optional(bool, true)
    private-6    = optional(bool, false)
    restricted   = optional(bool, true)
    restricted-6 = optional(bool, false)
  })
  default = {}
}

variable "delete_default_routes_on_create" {
  description = "Set to true to delete the default routes at creation time."
  type        = bool
  default     = false
}

variable "description" {
  description = "An optional description of this resource (triggers recreation on change)."
  type        = string
  default     = "Terraform-managed."
}

variable "dns_policy" {
  description = "DNS policy setup for the VPC."
  type = object({
    inbound = optional(bool)
    logging = optional(bool)
    outbound = optional(object({
      private_ns = list(string)
      public_ns  = list(string)
    }))
  })
  default = null
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    subnets_folder = string
  })
  default = null
}

variable "firewall_policy_enforcement_order" {
  description = "Order that Firewall Rules and Firewall Policies are evaluated. Can be either 'BEFORE_CLASSIC_FIREWALL' or 'AFTER_CLASSIC_FIREWALL'."
  type        = string
  nullable    = false
  default     = "AFTER_CLASSIC_FIREWALL"

  validation {
    condition     = var.firewall_policy_enforcement_order == "BEFORE_CLASSIC_FIREWALL" || var.firewall_policy_enforcement_order == "AFTER_CLASSIC_FIREWALL"
    error_message = "Enforcement order must be BEFORE_CLASSIC_FIREWALL or AFTER_CLASSIC_FIREWALL."
  }
}

variable "ipv6_config" {
  description = "Optional IPv6 configuration for this network."
  type = object({
    enable_ula_internal = optional(bool)
    internal_range      = optional(string)
  })
  nullable = false
  default  = {}
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes. The minimum value for this field is 1460 (the default) and the maximum value is 1500 bytes."
  type        = number
  default     = null
}

variable "name" {
  description = "The name of the network being created."
  type        = string
}

variable "peering_config" {
  description = "VPC peering configuration."
  type = object({
    peer_vpc_self_link = string
    create_remote_peer = optional(bool, true)
    export_routes      = optional(bool)
    import_routes      = optional(bool)
  })
  default = null
}

variable "project_id" {
  description = "The ID of the project where this VPC will be created."
  type        = string
}

variable "psa_config" {
  description = "The Private Service Access configuration for Service Networking."
  type = object({
    ranges        = map(string)
    export_routes = optional(bool, false)
    import_routes = optional(bool, false)
  })
  default = null
}

variable "routes" {
  description = "Network routes, keyed by name."
  type = map(object({
    description   = optional(string, "Terraform-managed.")
    dest_range    = string
    next_hop_type = string # gateway, instance, ip, vpn_tunnel, ilb
    next_hop      = string
    priority      = optional(number)
    tags          = optional(list(string))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for r in var.routes :
      contains(["gateway", "instance", "ip", "vpn_tunnel", "ilb"], r.next_hop_type)
    ])
    error_message = "Unsupported next hop type for route."
  }
}

variable "routing_mode" {
  description = "The network routing mode (default 'GLOBAL')."
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = var.routing_mode == "GLOBAL" || var.routing_mode == "REGIONAL"
    error_message = "Routing type must be GLOBAL or REGIONAL."
  }
}

variable "shared_vpc_host" {
  description = "Enable shared VPC for this project."
  type        = bool
  default     = false
}

variable "shared_vpc_service_projects" {
  description = "Shared VPC service projects to register with this host."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnet configuration."
  type = list(object({
    name                  = string
    ip_cidr_range         = string
    region                = string
    description           = optional(string)
    enable_private_access = optional(bool, true)
    flow_logs_config = optional(object({
      aggregation_interval = optional(string)
      filter_expression    = optional(string)
      flow_sampling        = optional(number)
      metadata             = optional(string)
      # only if metadata == "CUSTOM_METADATA"
      metadata_fields = optional(list(string))
    }))
    ipv6 = optional(object({
      access_type = optional(string, "INTERNAL")
      # this field is marked for internal use in the API documentation
      # enable_private_access = optional(string)
    }))
    secondary_ip_ranges = optional(map(string))

    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = []
  nullable = false
}

variable "subnets_proxy_only" {
  description = "List of proxy-only subnets for Regional HTTPS or Internal HTTPS load balancers. Note: Only one proxy-only subnet for each VPC network in each region can be active."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    description   = optional(string)
    active        = optional(bool, true)
    global        = optional(bool, false)

    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = []
  nullable = false
}

variable "subnets_psc" {
  description = "List of subnets for Private Service Connect service producers."
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    description   = optional(string)

    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = []
  nullable = false
}

variable "vpc_create" {
  description = "Create VPC. When set to false, uses a data source to reference existing VPC."
  type        = bool
  default     = true
}

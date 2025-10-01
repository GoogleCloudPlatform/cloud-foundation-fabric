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

variable "auto_create_subnetworks" {
  description = "Set to true to create an auto mode subnet, defaults to custom mode."
  type        = bool
  default     = false
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    tag_values = optional(map(string), {})
    project_ids = optional(map(string), {})
    regions     = optional(map(string), {})
  })
  default  = {}
  nullable = false
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

variable "network_profile" {
  description = "A full or partial URL of the network profile to apply. This can only be set at resource creation time."
  type        = string
  default     = null
}

variable "network_attachments" {
  description = "PSC network attachments, names as keys."
  type = map(object({
    subnet                = string
    automatic_connection  = optional(bool, false)
    description           = optional(string, "Terraform-managed.")
    producer_accept_lists = optional(list(string))
    producer_reject_lists = optional(list(string))
  }))
  nullable = false
  default  = {}
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

variable "policy_based_routes" {
  description = "Policy based routes, keyed by name."
  type = map(object({
    description         = optional(string, "Terraform-managed.")
    labels              = optional(map(string))
    priority            = optional(number)
    next_hop_ilb_ip     = optional(string)
    use_default_routing = optional(bool, false)
    filter = optional(object({
      ip_protocol = optional(string)
      dest_range  = optional(string)
      src_range   = optional(string)
    }), {})
    target = optional(object({
      interconnect_attachment = optional(string)
      tags                    = optional(list(string))
    }), {})
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for r in var.policy_based_routes :
      contains(["TCP", "UDP", "ALL", null], r.filter.ip_protocol)
      if r.filter.ip_protocol != null
    ])
    error_message = "Unsupported protocol for route."
  }
  validation {
    condition = alltrue([
      for r in var.policy_based_routes :
      (
        (r.use_default_routing == true ? 1 : 0)
        +
        (r.next_hop_ilb_ip != null ? 1 : 0)
      ) == 1
    ])
    error_message = "Either set `use_default_routing = true` or specify an internal passthrough LB IP."
  }
  validation {
    condition = alltrue([
      for r in var.policy_based_routes :
      r.target.tags == null || r.target.interconnect_attachment == null
    ])
    error_message = "Either use virtual machine tags or a vlan attachment region as a target."
  }
}

variable "project_id" {
  description = "The ID of the project where this VPC will be created."
  type        = string
}

variable "psa_configs" {
  description = "The Private Service Access configuration."
  type = list(object({
    deletion_policy  = optional(string, null)
    ranges           = map(string)
    export_routes    = optional(bool, false)
    import_routes    = optional(bool, false)
    peered_domains   = optional(list(string), [])
    range_prefix     = optional(string)
    service_producer = optional(string, "servicenetworking.googleapis.com")
  }))
  nullable = false
  default  = []
  validation {
    condition = (
      length(var.psa_configs) == length(toset([
        for v in var.psa_configs : v.service_producer
      ]))
    )
    error_message = "At most one configuration is possible for each service producer."
  }
  validation {
    condition = alltrue([
      for v in var.psa_configs : (
        v.deletion_policy == null || v.deletion_policy == "ABANDON"
      )
    ])
    error_message = "Deletion policy supports only ABANDON."
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

variable "tag_bindings" {
  description = "Tag bindings for the VPC network, in key => value format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "routers" {
  description = "Cloud Routers to create in this VPC, keyed by router name."
  type = map(object({
    region                          = string
    description                     = optional(string, "Terraform managed.")
    asn                             = optional(number)
    keepalive_interval              = optional(number)
    advertise_mode                  = optional(string)
    advertised_groups               = optional(list(string))
    advertised_ip_ranges = optional(map(object({
      range       = string
      description = optional(string)
    })))
  }))
  default  = {}
  nullable = false
}

variable "vpc_reuse" {
  description = "Reuse existing VPC if not null. If the network_id number is not passed in, a data source is used."
  type = object({
    use_data_source = optional(bool, true)
    attributes = optional(object({
      network_id = number
    }))
  })
  default = null
  validation {
    condition = (
      try(var.vpc_reuse.use_data_source, null) != false ||
      try(var.vpc_reuse.attributes, null) != null
    )
    error_message = "Reuse datasource can be disabled only if attributes are set."
  }
}

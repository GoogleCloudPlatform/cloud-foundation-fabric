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

variable "dns_config" {
  description = "DNS configuration."
  type = object({
    client_networks = optional(list(string))
    domain          = optional(string, "gce.example.")
    hostname        = optional(string)
  })
  nullable = false
  default  = {}
}

variable "instances_config" {
  description = "Configuration for instances."
  type = object({
    machine_type = optional(string, "e2-micro")
    zones        = optional(list(string), ["b"])
  })
  nullable = false
  default  = {}
  validation {
    condition     = length(var.instances_config.zones) > 0
    error_message = "At least one zone is required for instances."
  }
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  nullable    = false
  default     = "lb-xr-00"
}

variable "project_id" {
  description = "Project used to create resources."
  type        = string
  nullable    = false
}

variable "vpc_config" {
  description = "VPC configuration for load balancer and instances. Subnets are keyed by region."
  type = object({
    network           = string
    subnets           = map(string)
    subnets_instances = optional(map(string))
    firewall_config = optional(object({
      proxy_subnet_ranges   = list(string)
      client_allowed_ranges = optional(list(string))
      enable_health_check   = optional(bool, true)
      enable_iap_ssh        = optional(bool, false)
    }))
    proxy_subnets_config = optional(map(string))
  })
  nullable = false
  validation {
    condition     = try(regex("/", var.vpc_config.network), null) != null
    error_message = "Network must be a network id or self link, not a name."
  }
  validation {
    condition = alltrue([
      for k, v in var.vpc_config.subnets : try(regex("/", v), null) != null
    ])
    error_message = "Subnet values must be ids or self links, not names."
  }
  validation {
    condition = (
      var.vpc_config.subnets_instances == null
      ||
      keys(var.vpc_config.subnets) == keys(coalesce(var.vpc_config.subnets_instances, {}))
    )
    error_message = "Instance subnet regions must match load balancer regions if defined."
  }
  validation {
    condition = (
      var.vpc_config.proxy_subnets_config == null
      ||
      keys(var.vpc_config.subnets) == keys(coalesce(var.vpc_config.proxy_subnets_config, {}))
    )
    error_message = "Proxy subnet regions must match load balancer regions if defined."
  }
  validation {
    condition = alltrue([
      for k, v in coalesce(var.vpc_config.subnets_instances, {}) :
      try(regex("/", v), null) != null
    ])
    error_message = "Instance subnet values must be ids or self links, not names."
  }
}

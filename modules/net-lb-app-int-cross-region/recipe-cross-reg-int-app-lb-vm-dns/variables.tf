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
    count        = optional(number, 1)
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
  description = "Prefix used for or in resource names."
  type        = string
  nullable    = false
  default     = "lb-xr-00"
}

variable "project_id" {
  description = "Project used to create resources."
  type        = string
  nullable    = false
}

variable "regions" {
  description = "Regions used for the compute resources, use shortnames as keys."
  type        = map(string)
  nullable    = false
  default = {
    ew1 = "europe-west1"
    ew3 = "europe-west3"
  }
  validation {
    condition     = length(var.regions) >= 2
    error_message = "At least two regions are required."
  }
}

variable "vpc_config" {
  description = "VPC configuration for load balancer and instances."
  type = object({
    load_balancer_subnets = map(string)
    network               = string
    instance_subnets      = optional(map(string))
  })
  nullable = false
  validation {
    condition = (
      toset([
        for s in var.vpc_config.load_balancer_subnets :
        regex("/regions/([^/]+)/", s)
      ])
      ==
      toset([
        for s in coalesce(
          var.vpc_config.instance_subnets,
          var.vpc_config.load_balancer_subnets
        ) : regex("/regions/([^/]+)/", s)
      ])
    )
    error_message = "Instance subnet regions must match load balancer regions."
  }
}

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

variable "data_transfer" {
  description = "Site-to-site data transfer feature, available only in some regions."
  type        = bool
  default     = false
}

variable "hub" {
  description = "The NCC hub. You should either provide an existing hub id or a hub name if create is true."
  type = object({
    create      = optional(bool, false)
    description = optional(string)
    id          = optional(string)
    name        = optional(string)
  })
  validation {
    condition     = var.hub.create && var.hub.name != null || var.hub.create == false && var.hub.id != null
    error_message = "Name is required for configuring new ncc hub while referencing existing hub requires id."
  }
}

variable "name" {
  description = "The name of the NCC spoke."
  type        = string
}

variable "project_id" {
  description = "The ID of the project where the NCC hub & spokes will be created."
  type        = string
}

variable "region" {
  description = "Region where the spoke is located."
  type        = string
}

variable "router_appliances" {
  description = "List of router appliances this spoke is associated with."
  type = list(object({
    internal_ip  = string
    vm_self_link = string
  }))
}

variable "router_config" {
  description = "Configuration of the Cloud Router."
  type = object({
    asn = number
    custom_advertise = optional(object({
      all_subnets = bool
      ip_ranges   = map(string)
    }))
    ip_interface0   = string
    ip_interface1   = string
    keepalive       = optional(number)
    peer_asn        = number
    routes_priority = optional(number, 100)
  })
}

variable "vpc_config" {
  description = "Network and subnetwork for the CR interfaces."
  type = object({
    network_name     = string
    subnet_self_link = string
  })
}

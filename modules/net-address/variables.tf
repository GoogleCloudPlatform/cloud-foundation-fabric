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

variable "external_addresses" {
  description = "Map of external addresses, keyed by name."
  type = map(object({
    region      = string
    description = optional(string, "Terraform managed.")
    ipv6 = optional(object({
      endpoint_type = string
    }))
    labels = optional(map(string), {})
    name   = optional(string)
  }))
  default = {}
  validation {
    condition = (
      try(var.external_addresses.ipv6, null) == null
      || can(regex("^(NETLB|VM)$", try(var.external_addresses.ipv6.endpoint_type, null)))
    )
    error_message = "IPv6 endpoint type must be NETLB, VM."
  }
}

variable "global_addresses" {
  description = "List of global addresses to create."
  type = map(object({
    description = optional(string, "Terraform managed.")
    ipv6        = optional(map(string)) # To be left empty for ipv6
    name        = optional(string)
  }))
  default = {}
}

variable "internal_addresses" {
  description = "Map of internal addresses to create, keyed by name."
  type = map(object({
    region      = string
    subnetwork  = string
    address     = optional(string)
    description = optional(string, "Terraform managed.")
    ipv6        = optional(map(string)) # To be left empty for ipv6
    labels      = optional(map(string))
    name        = optional(string)
    purpose     = optional(string)
    tier        = optional(string)
  }))
  default = {}
}

variable "ipsec_interconnect_addresses" {
  description = "Map of internal addresses used for HPA VPN over Cloud Interconnect."
  type = map(object({
    region        = string
    address       = string
    network       = string
    description   = optional(string, "Terraform managed.")
    name          = optional(string)
    prefix_length = number
  }))
  default = {}
}

# variable "internal_address_labels" {
#   description = "Optional labels for internal addresses, keyed by address name."
#   type        = map(map(string))
#   default     = {}
# }

variable "project_id" {
  description = "Project where the addresses will be created."
  type        = string
}

variable "psa_addresses" {
  description = "Map of internal addresses used for Private Service Access."
  type = map(object({
    address       = string
    network       = string
    prefix_length = number
    description   = optional(string, "Terraform managed.")
    name          = optional(string)

  }))
  default = {}
}

variable "psc_addresses" {
  description = "Map of internal addresses used for Private Service Connect."
  type = map(object({
    address     = string
    network     = string
    description = optional(string, "Terraform managed.")
    name        = optional(string)
  }))
  default = {}
}

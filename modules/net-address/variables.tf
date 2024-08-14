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

variable "external_addresses" {
  description = "Map of external addresses, keyed by name."
  type = map(object({
    region      = string
    description = optional(string, "Terraform managed.")
    ipv6 = optional(object({
      endpoint_type = string
    }))
    labels     = optional(map(string), {})
    name       = optional(string)
    subnetwork = optional(string) # for IPv6
    tier       = optional(string)
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

variable "network_attachments" {
  description = "PSC network attachments, names as keys."
  type = map(object({
    subnet_self_link      = string
    automatic_connection  = optional(bool, false)
    description           = optional(string, "Terraform-managed.")
    producer_accept_lists = optional(list(string))
    producer_reject_lists = optional(list(string))
  }))
  nullable = false
  default  = {}
}

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
    address          = string
    description      = optional(string, "Terraform managed.")
    name             = optional(string)
    network          = optional(string)
    region           = optional(string)
    subnet_self_link = optional(string)
    service_attachment = optional(object({ # so we can safely check if service_attachemnt != null in for_each
      psc_service_attachment_link = string
      global_access               = optional(bool)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for key, value in var.psc_addresses : (value.region != null || (value.region == null && value.network != null))])
    error_message = "Provide network if creating global PSC addresses / endpoints."
  }
  validation {
    condition     = alltrue([for key, value in var.psc_addresses : (value.region == null || (value.region != null && value.subnet_self_link != null))])
    error_message = "Provide subnet_self_link if creating regional PSC addresses / endpoints."
  }
  validation {
    condition     = alltrue([for key, value in var.psc_addresses : !(value.subnet_self_link != null && value.network != null)])
    error_message = "Do not provide network and subnet_self_link at the same time"
  }
}

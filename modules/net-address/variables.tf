/**
 * Copyright 2026 Google LLC
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
    locations           = optional(map(string), {})
    networks            = optional(map(string), {})
    project_ids         = optional(map(string), {})
    service_attachments = optional(map(string), {})
    subnets             = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

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
    condition = alltrue([
      for k, v in var.external_addresses :
      try(v.ipv6, null) == null
      || can(
        regex("^(NETLB|VM)$",
        try(v.ipv6.endpoint_type, null))
      )
    ])
    error_message = "IPv6 endpoint type must be NETLB, VM."
  }
}

variable "global_addresses" {
  description = "List of global addresses to create."
  type = map(object({
    description = optional(string, "Terraform managed.")
    ipv6        = optional(map(string)) # To be left empty for IPv6
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
    ipv6        = optional(map(string)) # To be left empty for IPv6
    labels      = optional(map(string))
    name        = optional(string)
    purpose     = optional(string)
  }))
  default = {}
}

variable "ipsec_interconnect_addresses" {
  description = "Map of internal addresses used for HPA VPN over Cloud Interconnect."
  type = map(object({
    address       = string
    network       = string
    region        = string
    prefix_length = number
    description   = optional(string, "Terraform managed.")
    name          = optional(string)
  }))
  default = {}
}

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

variable "psc_endpoints" {
  description = "Map of PSC endpoints, keyed by name. Regional endpoints for Google APIs are configured via regional_endpoint."
  type = map(object({
    address          = optional(string)
    description      = optional(string, "Terraform managed.")
    name             = optional(string)
    network          = optional(string)
    region           = optional(string)
    subnet_self_link = optional(string)
    # regional or multi-regional Google APIs (*.rep.googleapis.com)
    regional_endpoint = optional(object({
      target_google_api = string
      deletion_policy   = optional(string)
      global_access     = optional(bool)
      labels            = optional(map(string))
    }))
    # so we can safely check if service_attachemnt != null in for_each
    service_attachment = optional(object({
      psc_service_attachment_link = string
      global_access               = optional(bool)
      service_directory_registration = optional(object({
        namespace = optional(string)
        region    = optional(string)
      }))
    }))
  }))
  default = {}
  validation {
    condition = alltrue(
      [
        for key, value in var.psc_endpoints
        : (
          value.address != null
          || (value.address == null && value.subnet_self_link != null)
        )
      ]
    )
    error_message = "Provide address if creating a global PSC addresses / endpoints."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.psc_endpoints
        : (
          value.region != null
          || (value.region == null && value.network != null
          )
        )
      ]
    )
    error_message = "Provide network if creating global PSC addresses / endpoints."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.psc_endpoints
        : (
          value.region == null
          || (value.region != null && value.subnet_self_link != null)
        )
      ]
    )
    error_message = "Provide subnet_self_link if creating regional PSC addresses / endpoints."
  }
  validation {
    condition = alltrue(
      [
        for key, value in var.psc_endpoints
        : (
          value.regional_endpoint != null
          || !(value.subnet_self_link != null && value.network != null)
        )
      ]
    )
    error_message = "Do not provide network and subnet_self_link at the same time, unless creating regional endpoints for Google APIs."
  }
  validation {
    condition = alltrue([
      for k, v in var.psc_endpoints :
      !(v.regional_endpoint != null && v.service_attachment != null)
    ])
    error_message = "Do not provide regional_endpoint and service_attachment at the same time."
  }
  validation {
    condition = alltrue([
      for k, v in var.psc_endpoints :
      v.regional_endpoint == null
      ? true
      : (
        v.network != null
        && v.region != null
        && v.subnet_self_link != null
      )
    ])
    error_message = "Provide network, region and subnet_self_link if creating regional endpoints for Google APIs."
  }
  validation {
    condition = alltrue([
      for k, v in var.psc_endpoints :
      v.regional_endpoint == null
      ? true
      : endswith(v.regional_endpoint.target_google_api, ".rep.googleapis.com")
    ])
    error_message = "Target Google API must be a regional or multi-regional endpoint in the `<api>.<location>.rep.googleapis.com` format."
  }
  validation {
    condition = alltrue([
      for k, v in var.psc_endpoints :
      try(v.regional_endpoint.deletion_policy, null) == null
      ? true
      : contains(
        ["ABANDON", "DELETE", "PREVENT"], v.regional_endpoint.deletion_policy
      )
    ])
    error_message = "Regional endpoint deletion policy must be one of ABANDON, DELETE, PREVENT."
  }
  validation {
    condition = alltrue([
      for k, v in var.psc_endpoints :
      v.regional_endpoint == null
      ? true
      : can(regex(
        "^[-a-z0-9](?:[-a-z0-9]{0,44})[a-z0-9]$", coalesce(v.name, k)
      ))
    ])
    error_message = "Regional endpoint names must be 2-46 characters long, and only contain lowercase letters, numbers and hyphens."
  }
}

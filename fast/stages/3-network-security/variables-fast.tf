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

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}

variable "cas_configs" {
  # tfdoc:variable:source 2-security
  description = "The CAS pools and CA ids, by environment."
  type = object({
    dev = map(object({
      ca_pool_id = string
      ca_ids     = map(string)
      location   = string
    }))
    prod = map(object({
      ca_pool_id = string
      ca_ids     = map(string)
      location   = string
    }))
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created."
  type = object({
    networking      = string
    networking-dev  = string
    networking-prod = string
  })
  nullable = false
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Host project for the shared VPC."
  type = object({
    dev-spoke-0  = optional(string)
    prod-spoke-0 = optional(string)
  })
  nullable = false
  default  = {}
}

variable "ngfw_tls_configs" {
  # tfdoc:variable:source 2-security
  description = "The CAS and trust configurations key names to be used for NGFW Enterprise."
  type = object({
    keys = optional(object({
      dev = optional(object({
        cas           = optional(list(string), [])
        trust_configs = optional(list(string), [])
      }), {})
      prod = optional(object({
        cas           = optional(list(string), [])
        trust_configs = optional(list(string), [])
      }), {})
    }), {})
    tls_inspection = optional(object({
      enabled               = optional(bool, false)
      exclude_public_ca_set = optional(bool, false)
      min_tls_version       = optional(string, "TLS_1_0")
    }), {})
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "organization" {
  # tfdoc:variable:source 00-globals
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 12
    error_message = "Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  }
}

variable "tls_inspection_policy_ids" {
  # tfdoc:variable:source 2-security
  description = "TLS inspection policy ids for NGFW by environment and region."
  type = object({
    dev  = optional(map(string))
    prod = optional(map(string))
  })
  nullable = false
  default = {
    dev  = {}
    prod = {}
  }
}

variable "vpc_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Self link for the shared VPC."
  type = object({
    dev-spoke-0  = string
    prod-spoke-0 = string
  })
  nullable = false
}

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

variable "certificates" {
  description = "Certificates."
  type = map(object({
    description = optional(string)
    labels      = optional(map(string), {})
    location    = optional(string)
    scope       = optional(string)
    self_managed = optional(object({
      pem_certificate = string
      pem_private_key = string
    }))
    managed = optional(object({
      domains            = list(string)
      dns_authorizations = optional(list(string))
      issuance_config    = optional(string)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([for k, v in var.certificates : (
      v.self_managed != null && v.managed == null
      || v.self_managed == null && v.managed != null
    )])
    error_message = "Either a self-managed or a managed configuration must be specified for a certificate."
  }
  validation {
    condition = alltrue([for k, v in var.certificates : v.managed == null ? true :
      !(v.managed.dns_authorizations != null
      && v.managed.issuance_config != null)
    ])
    error_message = "Both DNS authorizations and issuance cannot be specified."
  }
}

variable "dns_authorizations" {
  description = "DNS authorizations."
  type = map(object({
    domain      = string
    description = optional(string)
    location    = optional(string)
    type        = optional(string)
    labels      = optional(map(string))
  }))
  default  = {}
  nullable = false
}

variable "issuance_configs" {
  description = "Issuance configs."
  type = map(object({
    ca_pool                    = string
    description                = optional(string)
    key_algorithm              = string
    labels                     = optional(map(string), {})
    lifetime                   = string
    rotation_window_percentage = number
  }))
  default  = {}
  nullable = false
}

variable "map" {
  description = "Map attributes."
  type = object({
    name        = string
    description = optional(string)
    labels      = optional(map(string), {})
    entries = optional(map(object({
      description  = optional(string)
      hostname     = optional(string)
      labels       = optional(map(string), {})
      matcher      = optional(string)
      certificates = list(string)
    })), {})
  })
  default = null

  validation {
    condition     = var.map == null ? true : alltrue([for k, v in var.map.entries : v.hostname == null && v.matcher != null || v.hostname != null && v.matcher == null])
    error_message = "Either hostname or matcher must be specified for an entry."
  }
}

variable "project_id" {
  description = "Project id."
  type        = string
}


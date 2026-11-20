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
    addresses           = optional(map(string), {})
    locations           = optional(map(string), {})
    networks            = optional(map(string), {})
    project_ids         = optional(map(string), {})
    service_attachments = optional(map(string), {})
    subnets             = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "global_apis" {
  description = "Global Private Service Connect endpoints for Google APIs, keyed by name."
  type = map(object({
    address              = string
    network              = string
    target               = string
    address_create       = optional(bool, true)
    deletion_policy      = optional(string)
    description          = optional(string)
    labels               = optional(map(string))
    name                 = optional(string)
    no_automate_dns_zone = optional(bool)
    service_directory_registration = optional(object({
      namespace = optional(string)
      region    = optional(string)
    }))
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.global_apis : v.address_create != null
    ])
    error_message = "address_create cannot be null."
  }
  validation {
    condition = alltrue([
      for k, v in var.global_apis : contains(["all-apis", "vpc-sc"], v.target)
    ])
    error_message = "Global API target must be 'all-apis' or 'vpc-sc'."
  }
  validation {
    condition = alltrue([
      for k, v in var.global_apis : can(
        regex(
          "^[a-z][a-z0-9]{0,19}$",
          "${var.prefix == null ? "" : var.prefix}${coalesce(v.name, k)}"
        )
      )
    ])
    error_message = "Global API endpoint names must be 1-20 lowercase letters and digits, starting with a letter (no hyphens)."
  }
  validation {
    condition = alltrue([
      for k, v in var.global_apis :
      v.deletion_policy == null ? true : contains(
        ["ABANDON", "DELETE", "PREVENT"], v.deletion_policy
      )
    ])
    error_message = "Deletion policy must be one of ABANDON, DELETE, PREVENT."
  }
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project where the PSC endpoints will be created."
  type        = string
}

variable "published_services" {
  description = "Regional Private Service Connect endpoints for published services, keyed by name."
  type = map(object({
    region                      = string
    subnetwork                  = string
    target                      = string
    address                     = optional(string)
    address_create              = optional(bool, true)
    deletion_policy             = optional(string)
    description                 = optional(string)
    global_access               = optional(bool)
    labels                      = optional(map(string))
    name                        = optional(string)
    no_automate_dns_zone        = optional(bool)
    recreate_closed_psc         = optional(bool)
    service_directory_namespace = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.published_services : v.address_create != null
    ])
    error_message = "address_create cannot be null."
  }
  validation {
    condition = alltrue([
      for k, v in var.published_services :
      coalesce(v.address_create, false) || v.address != null
    ])
    error_message = "address must be set when address_create is false."
  }
  validation {
    condition = alltrue([
      for k, v in var.published_services :
      v.deletion_policy == null ? true : contains(
        ["ABANDON", "DELETE", "PREVENT"], v.deletion_policy
      )
    ])
    error_message = "Deletion policy must be one of ABANDON, DELETE, PREVENT."
  }
}

variable "regional_apis" {
  description = "Regional and multi-regional Private Service Connect endpoints for Google APIs (*.rep.googleapis.com), keyed by name."
  type = map(object({
    network         = string
    region          = string
    subnetwork      = string
    target          = string
    address         = optional(string)
    address_create  = optional(bool, true)
    deletion_policy = optional(string)
    description     = optional(string)
    global_access   = optional(bool)
    labels          = optional(map(string))
    name            = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.regional_apis : v.address_create != null
    ])
    error_message = "address_create cannot be null."
  }
  validation {
    condition = alltrue([
      for k, v in var.regional_apis :
      coalesce(v.address_create, false) || v.address != null
    ])
    error_message = "address must be set when address_create is false."
  }
  validation {
    condition = alltrue([
      for k, v in var.regional_apis :
      endswith(v.target, ".rep.googleapis.com")
    ])
    error_message = "Regional API target must match '<api>.<location>.rep.googleapis.com'."
  }
  validation {
    condition = alltrue([
      for k, v in var.regional_apis : can(
        regex(
          "^[a-z][-a-z0-9]{0,44}[a-z0-9]$",
          "${var.prefix == null ? "" : "${var.prefix}-"}${coalesce(v.name, k)}"
        )
      )
    ])
    error_message = "Regional API endpoint names must be 2-46 characters of lowercase letters, digits, and hyphens, starting with a letter."
  }
  validation {
    condition = alltrue([
      for k, v in var.regional_apis :
      v.deletion_policy == null ? true : contains(
        ["ABANDON", "DELETE", "PREVENT"], v.deletion_policy
      )
    ])
    error_message = "Deletion policy must be one of ABANDON, DELETE, PREVENT."
  }
}

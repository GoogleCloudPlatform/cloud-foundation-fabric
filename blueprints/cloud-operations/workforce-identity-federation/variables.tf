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

variable "organization" {
  description = "Organization details."
  type = object({
    id          = number
    domain      = optional(string)
    customer_id = optional(string)
  })
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "workforce_identity_pools" {
  description = "Workforce Identity Federation pools."
  type = map(object({
    description  = optional(string, "Created and managed by Terraform")
    display_name = optional(string)
    disabled     = optional(bool, false)
    providers    = map(object({
      issuer              = string
      description         = optional(string, "Created and managed by Terraform")
      display_name        = optional(string)
      attribute_condition = optional(string)
      disabled            = optional(bool, false)
      saml_metadata_url   = optional(string)
    }))
    location            = optional(string, "global")
    session_duration    = optional(string, "3600s")
    access_restrictions = optional(object({
      allowed_domains   = optional(list(string), [])
      disable_programmatic_signin = optional(bool, false)
    }))
  }))
  default  = {}
  nullable = false
}
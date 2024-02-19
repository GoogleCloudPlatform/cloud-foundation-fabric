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

variable "description" {
  description = "Resource description for data exchange."
  default     = null
  type        = string
}

variable "documentation" {
  description = "Documentation describing the data exchange."
  default     = null
  type        = string
}

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    listings = optional(string)
  })
  nullable = false
  default  = {}
}

variable "icon" {
  description = "Base64 encoded image representing the data exchange."
  default     = null
  type        = string
}

variable "listings" {
  description = "Listings definitions in the form {LISTING_ID => LISTING_CONFIGS}. LISTING_ID must contain only Unicode letters, numbers (0-9), underscores (_). Should not use characters that require URL-escaping or characters outside of ASCII spaces."
  type = map(object({
    bigquery_dataset = string
    description      = optional(string)
    documentation    = optional(string)
    categories       = optional(list(string))
    icon             = optional(string)
    primary_contact  = optional(string)
    request_access   = optional(string)
    data_provider = optional(object({
      name            = string
      primary_contact = optional(string)
    }))
    iam = optional(map(list(string)))
    publisher = optional(object({
      name            = string
      primary_contact = optional(string)
    }))
    restricted_export_config = optional(object({
      enabled               = optional(bool)
      restrict_query_result = optional(bool)
    }))
  }))
  default = {}
}

variable "name" {
  description = "The ID of the data exchange. Must contain only Unicode letters, numbers (0-9), underscores (_). Should not use characters that require URL-escaping or characters outside of ASCII spaces."
  type        = string
}

variable "prefix" {
  description = "Optional prefix for data exchange ID."
  type        = string
  default     = null
}

variable "primary_contact" {
  description = "Email or URL of the primary point of contact of the data exchange."
  type        = string
  default     = null
}

variable "project_id" {
  description = "The ID of the project where the data exchange will be created."
  type        = string
}

variable "region" {
  description = "Region for the data exchange."
  type        = string
}

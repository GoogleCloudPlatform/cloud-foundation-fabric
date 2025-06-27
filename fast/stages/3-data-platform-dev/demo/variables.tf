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
variable "authorized_dataset_on_curated" {
  description = "Authorized Dataset."
  type        = string
}

variable "encryption_keys" {
  description = "Default encryption keys for services, in service => { region => key id } format. Overridable on a per-object basis."
  type = object({
    bigquery = optional(map(string), {})
    composer = optional(map(string), {})
    storage  = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "location" {
  description = "Default location used when no location is specified."
  type        = string
  nullable    = false
  default     = "europe-west8"
}

variable "prefix" {
  description = "Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 12
    error_message = "Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  }
}

variable "project_id" {
  description = "Project ID to deploy resources."
  type        = string
  nullable    = false
}

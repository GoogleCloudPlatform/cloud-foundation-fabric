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

variable "context" {
  description = "External context used in replacements."
  type = object({
    condition_vars      = optional(map(map(string)), {})
    custom_roles        = optional(map(string), {})
    folder_ids          = optional(map(string), {})
    iam_principals      = optional(map(string), {})
    project_ids         = optional(map(string), {})
    service_account_ids = optional(map(string), {})
    storage_buckets     = optional(map(string), {})
    tag_values          = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "create_ignore_already_exists" {
  description = "If set to true, skip service account creation if a service account with the same email already exists."
  type        = bool
  default     = null
  validation {
    condition     = !(var.create_ignore_already_exists == true && var.service_account_create == false)
    error_message = "Cannot set create_ignore_already_exists when service_account_create is false."
  }
}

variable "description" {
  description = "Optional description."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name of the service account to create."
  type        = string
  default     = "Terraform-managed."
}

variable "name" {
  description = "Name of the service account to create."
  type        = string
}

variable "prefix" {
  description = "Prefix applied to service account names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "Project id where service account will be created."
  type        = string
}

variable "project_number" {
  description = "Project number of var.project_id. Set this to avoid permadiffs when creating tag bindings."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Create service account. When set to false, uses a data source to reference an existing service account."
  type        = bool
  default     = true
  nullable    = false
}

variable "tag_bindings" {
  description = "Tag bindings for this service accounts, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

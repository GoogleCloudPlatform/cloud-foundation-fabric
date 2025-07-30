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

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    custom_roles   = optional(map(string), {})
    folder_ids     = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
    tag_values     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "description" {
  description = "Human-readable description for the logging bucket."
  type        = string
  default     = null
}

variable "kms_key_name" {
  description = "To enable CMEK for a project logging bucket, set this field to a valid name. The associated service account requires cloudkms.cryptoKeyEncrypterDecrypter roles assigned for the key."
  type        = string
  default     = null
}

variable "location" {
  description = "Location of the bucket."
  type        = string
  default     = "global"
}

variable "log_analytics" {
  description = "Enable and configure Analytics Log."
  type = object({
    enable          = optional(bool, false)
    dataset_link_id = optional(string)
    description     = optional(string, "Log Analytics Dataset")
  })
  nullable = false
  default  = {}
}

variable "name" {
  description = "Name of the logging bucket."
  type        = string
}

variable "parent" {
  description = "ID of the parent resource containing the bucket in the format 'project_id' 'folders/folder_id', 'organizations/organization_id' or 'billing_account_id'."
  type        = string
  nullable    = false
}

# parent type cannot be derived from parent id as that might be dynamic

variable "parent_type" {
  description = "Parent object type for the bucket (project, folder, organization, billing_account)."
  type        = string
  nullable    = false
  default     = "project"
}

variable "retention" {
  description = "Retention time in days for the logging bucket."
  type        = number
  default     = 30
}

variable "tag_bindings" {
  description = "Tag bindings for this bucket, in key => tag value id format."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "views" {
  description = "Log views for this bucket."
  type = map(object({
    filter      = string
    location    = optional(string)
    description = optional(string)
    iam         = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = {}
  nullable = false
}

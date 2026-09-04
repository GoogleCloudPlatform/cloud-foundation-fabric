# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    project_ids      = optional(map(string), {})
    service_accounts = optional(map(string), {})
  })
  nullable = false
  default  = {}
}

variable "description" {
  description = "A description of the pool."
  type        = string
  default     = "Managed by Terraform."
}

variable "disabled" {
  description = "Whether the workload identity pool is disabled."
  type        = bool
  default     = false
}

variable "display_name" {
  description = "A display name for the pool."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals" {
  description = "IAM bindings in {PRINCIPAL => [ROLES]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "identity_providers" {
  description = "Workload identity pool identity providers."
  type = map(object({
    attribute_condition = optional(string)
    attribute_mapping   = optional(map(string))
    description         = optional(string)
    disabled            = optional(bool, false)
    display_name        = optional(string)
    aws = optional(object({
      account_id = string
    }))
    oidc = optional(object({
      allowed_audiences = optional(list(string))
      issuer_uri        = string
      jwks_json         = optional(string)
    }))
    saml = optional(object({
      idp_metadata_xml = string
    }))
  }))
  default  = {}
  nullable = false
}

variable "name" {
  description = "The ID of the workload identity pool."
  type        = string
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
  description = "The project in which the workload identity pool belongs."
  type        = string
}

variable "service_account_impersonation" {
  description = "Service account impersonation bindings for the pool."
  type = map(object({
    service_account_id = string
    attribute_members  = optional(list(string), [])
    subjects           = optional(list(string), [])
  }))
  default  = {}
  nullable = false
}

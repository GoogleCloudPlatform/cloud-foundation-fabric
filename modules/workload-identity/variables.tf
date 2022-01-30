/**
 * Copyright 2022 Google LLC
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
  description = "Optional description"
  type        = string
  default     = null
}

variable "disabled" {
  description = "Flag indicating whether the workload identity pool is disabled"
  type        = bool
  default     = false
}

variable "display_name" {
  description = "Optional display name"
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project identifier"
  type        = string
}

variable "workload_identity_pool_id" {
  description = "Workload identity pool identifier"
  type        = string
}

variable "workload_identity_pool_providers" {
  description = "Map with the workload identity pool providers"
  type = map(object({
    attribute_condition = string
    attribute_mapping   = map(string)
    aws = object({
      account_id = string
    })
    description  = string
    display_name = string
    disabled     = bool
    oidc = object({
      allowed_audiences = list(string)
      issuer_uri        = string
    })
  }))
  validation {
    condition     = alltrue([for p in var.workload_identity_pool_providers : p.aws != null && p.oidc == null || p.aws == null && p.oidc != null])
    error_message = "Either aws or oidc needs to be specified for all providers."
  }
}

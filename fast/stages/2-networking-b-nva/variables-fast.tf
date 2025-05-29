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

# tfdoc:file:description FAST stage interface.

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

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

variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    project_iam_viewer = string
  })
  default = null
}

variable "environments" {
  # tfdoc:variable:source 0-globals
  description = "Environment names."
  type = map(object({
    name       = string
    tag_name   = string
    is_default = optional(bool, false)
  }))
  nullable = false
  validation {
    condition = anytrue([
      for k, v in var.environments : v.is_default == true
    ])
    error_message = "At least one environment should be marked as default."
  }
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folders to be used for the networking resources in folders/nnnnnnnnnnn format."
  type = object({
    networking      = string
    networking-dev  = optional(string)
    networking-prod = optional(string)
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

variable "security_profile_groups" {
  # tfdoc:variable:source 2-networking-ngfw
  description = "Security profile group ids used for policy rule substitutions."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "stage_configs" {
  # tfdoc:variable:source 1-resman
  description = "FAST stage configuration."
  type = object({
    networking = optional(object({
      short_name          = optional(string)
      iam_admin_delegated = optional(map(list(string)), {})
      iam_viewer          = optional(map(list(string)), {})
    }), {})
  })
  default  = {}
  nullable = false
}

variable "tag_values" {
  # tfdoc:variable:source 1-resman
  description = "Root-level tag values."
  type        = map(string)
  default     = {}
}

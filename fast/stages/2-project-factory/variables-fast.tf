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

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folders created in the resource management stage."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "groups" {
  # tfdoc:variable:source 0-bootstrap
  # https://cloud.google.com/docs/enterprise/setup-checklist
  description = "Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Host project for the shared VPC."
  type        = map(string)
  nullable    = false
  default     = {}
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

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Automation service accounts in name => email format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "tag_values" {
  # tfdoc:variable:source 1-resman
  description = "FAST-managed resource manager tag values."
  type        = map(string)
  nullable    = false
  default     = {}
}

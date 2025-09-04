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

variable "bootstrap_user" {
  description = "Email of the nominal user running this stage for the first time."
  type        = string
  default     = null
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    custom_roles          = optional(map(string), {})
    folder_ids            = optional(map(string), {})
    iam_principals        = optional(map(string), {})
    locations             = optional(map(string), {})
    kms_keys              = optional(map(string), {})
    notification_channels = optional(map(string), {})
    project_ids           = optional(map(string), {})
    service_account_ids   = optional(map(string), {})
    tag_keys              = optional(map(string), {})
    tag_values            = optional(map(string), {})
    vpc_host_projects     = optional(map(string), {})
    vpc_sc_perimeters     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    billing_accounts = optional(string, "data/billing-accounts")
    cicd             = optional(string)
    defaults         = optional(string, "data/defaults.yaml")
    folders          = optional(string, "data/folders")
    organization     = optional(string, "data/organization")
    projects         = optional(string, "data/projects")
  })
  nullable = false
  default  = {}
}

variable "org_policies_imports" {
  description = "List of org policies to import. These need to also be defined in data files."
  type        = list(string)
  nullable    = false
  default     = []
}

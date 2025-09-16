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

variable "environments" {
  description = "Environment names. When not defined, short name is set to the key and tag name to lower(name)."
  type = map(object({
    name       = optional(string)
    is_default = optional(bool, false)
    short_name = optional(string)
    tag_name   = optional(string)
  }))
  nullable = false
  validation {
    condition = anytrue([
      for k, v in var.environments : v.is_default == true
    ])
    error_message = "At least one environment should be marked as default."
  }
  validation {
    condition = alltrue([
      for k, v in var.environments : join(" ", regexall(
        "[a-zA-Z][a-zA-Z0-9\\s-]+[a-zA-Z0-9]", v.name
      )) == v.name
    ])
    error_message = "Environment names can only contain letters numbers dashes or spaces."
  }
  validation {
    condition = alltrue([
      for k, v in var.environments : (length(coalesce(v.short_name, k)) <= 4)
    ])
    error_message = "If environment key is longer than 4 characters, provide short_name that is at most 4 characters long."
  }
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    billing_accounts  = optional(string, "data/billing-accounts")
    cicd              = optional(string)
    defaults          = optional(string, "data/defaults.yaml")
    folders           = optional(string, "data/folders")
    organization      = optional(string, "data/organization")
    project_templates = optional(string, "data/templates")
    projects          = optional(string, "data/projects")
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

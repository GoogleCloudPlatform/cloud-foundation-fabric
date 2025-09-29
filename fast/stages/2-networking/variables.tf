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
  description = "Context-specific interpolations."
  type = object({
    custom_roles   = optional(map(string), {})
    folder_ids     = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
    tag_keys       = optional(map(string), {})
    tag_values     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    defaults          = optional(string, "data/defaults.yaml")
    dns               = optional(string, "data/dns")
    firewall-policies = optional(string, "data/firewall-policies")
    folders           = optional(string, "data/folders")
    interconnect      = optional(string, "data/interconnect")
    ncc-hubs          = optional(string, "data/ncc-hubs")
    projects          = optional(string, "data/projects")
    vpcs              = optional(string, "data/vpcs")
  })
  nullable = false
  default  = {}
}

variable "factories_index" {
  description = "Controls whether factory resources are keyed by path or id"
  type        = string
  default     = "by_path"
  validation {
    condition     = contains(["by_path", "by_id"], var.factories_index)
    error_message = "factories_index must be either 'by_path' or 'by_id'"
  }
}

variable "outputs_location" {
  description = "Path where tfvars files for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

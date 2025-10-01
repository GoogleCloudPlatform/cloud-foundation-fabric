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
    vpcs = optional(string, "data/vpcs")
    defaults = optional(string, "data/defaults.yaml")
  })
  nullable = false
  default = {}
}

# Stage-specific variables (FAST stage variables are in variables-fast.tf)

# Data directory for network configurations
variable "data_dir" {
  description = "Relative path for the folder storing configuration data for network resources."
  type        = string
  default     = "data"
}

# Stage configuration
variable "stage_name" {
  description = "Name of the current stage."
  type        = string
  default     = "2-networking"
}

# Output files configuration
variable "output_files" {
  description = "Output files configuration for downstream stages."
  type = object({
    enabled      = optional(bool, false)
    local_path   = optional(string, "~/fast-config")
    storage_bucket = optional(string)
  })
  default = {
    enabled = false
  }
}


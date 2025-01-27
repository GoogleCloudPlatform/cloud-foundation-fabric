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

variable "logging_data_access" {
  description = "Control activation of data access logs. The special 'allServices' key denotes configuration for all services."
  type = map(object({
    ADMIN_READ = optional(object({ exempted_members = optional(list(string)) })),
    DATA_READ  = optional(object({ exempted_members = optional(list(string)) })),
    DATA_WRITE = optional(object({ exempted_members = optional(list(string)) }))
  }))
  default  = {}
  nullable = false
}

variable "logging_exclusions" {
  description = "Logging exclusions for this folder in the form {NAME -> FILTER}."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging_settings" {
  description = "Default settings for logging resources."
  type = object({
    # TODO: add support for CMEK
    disable_default_sink = optional(bool)
    storage_location     = optional(string)
  })
  default = null
}

variable "logging_sinks" {
  description = "Logging sinks to create for the folder."
  type = map(object({
    bq_partitioned_table = optional(bool, false)
    description          = optional(string)
    destination          = string
    disabled             = optional(bool, false)
    exclusions           = optional(map(string), {})
    filter               = optional(string)
    iam                  = optional(bool, true)
    include_children     = optional(bool, true)
    intercept_children   = optional(bool, false)
    type                 = string
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      !v.intercept_children || (v.include_children && v.type == "project")
    ])
    error_message = "'type' must be set to 'project' if 'intercept_children' is 'true'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      contains(["bigquery", "logging", "project", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'project', 'pubsub', 'storage'."
  }
  validation {
    condition = alltrue([
      for k, v in var.logging_sinks :
      v.bq_partitioned_table != true || v.type == "bigquery"
    ])
    error_message = "Can only set bq_partitioned_table when type is `bigquery`."
  }
}

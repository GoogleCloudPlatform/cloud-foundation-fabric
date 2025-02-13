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

variable "databases" {
  description = "Databases."
  type = map(object({
    database_dialect       = optional(string)
    ddl                    = optional(list(string), [])
    deletion_protection    = optional(bool)
    enable_drop_protection = optional(bool)
    iam                    = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
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
    kms_key_name             = optional(string)
    version_retention_period = optional(string)
  }))
  default = {}
  validation {
    condition = alltrue(
      [for k, v in var.databases : v.database_dialect == null ? true : contains(["GOOGLE_STANDARD_SQL", "POSTGRESQL"], v.database_dialect)]
    )
    error_message = "Invalid database_dialect. If set, possible values are: GOOGLE_STANDARD_SQL, POSTGRESQL"
  }

  validation {
    condition = alltrue(
      [for k, v in var.databases : v.version_retention_period == null ? true : can(regex("\\d+[smhd]", v.version_retention_period))]
    )
    error_message = "Invalid version_retention_period. If set, the format has to be: \\d+[smhd]"
  }

}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
  }))
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
  }))
  nullable = false
  default  = {}
}

variable "instance" {
  description = "Instance attributes."
  type = object({
    autoscaling = optional(object({
      limits = optional(object({
        max_nodes            = optional(number)
        max_processing_units = optional(number)
        min_nodes            = optional(number)
        min_processing_units = optional(number)
      }))
      targets = optional(object({
        high_priority_cpu_utilization_percent = optional(number)
        storage_utilization_percent           = optional(number)
      }))
    }))
    config = optional(object({
      name = string
      auto_create = optional(object({
        base_config  = optional(string)
        display_name = optional(string)
        labels       = optional(map(string), {})
        replicas = list(object({
          location                = string
          type                    = string
          default_leader_location = bool
          }
        ))
      }))
    }))
    display_name     = optional(string)
    labels           = optional(map(string), {})
    name             = string
    num_nodes        = optional(number)
    processing_units = optional(number)
    force_destroy    = optional(bool)
  })
}

variable "instance_create" {
  description = "Set to false to manage databases and IAM bindings in an existing instance."
  type        = bool
  default     = true
}


variable "project_id" {
  description = "Project id."
  type        = string
}


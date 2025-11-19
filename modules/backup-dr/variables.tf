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

variable "backup_plans" {
  description = "Map of Backup Plans to create in this Vault."
  type = map(object({
    resource_type = string
    description   = optional(string)
    backup_rules = list(object({
      rule_id               = string
      backup_retention_days = number
      standard_schedule = object({
        recurrence_type  = string
        hourly_frequency = optional(number)
        days_of_week     = optional(list(string))
        days_of_month    = optional(list(number))
        months           = optional(list(string))
        week_day_of_month = optional(object({
          week_of_month = string
          day_of_week   = string
        }))
        time_zone = string
        backup_window = object({
          start_hour_of_day = number
          end_hour_of_day   = number
        })
      })
    }))
  }))
  default = {}
}

variable "location" {
  description = "Location for the Backup Vault and Plans (e.g. us-central1)."
  type        = string
}

variable "management_server_config" {
  description = "Configuration to create a Management Server. If null, no server is created."
  type = object({
    name     = string
    type     = optional(string, "BACKUP_RESTORE")
    location = optional(string)
    network_config = optional(object({
      network      = string
      peering_mode = optional(string, "PRIVATE_SERVICE_ACCESS")
    }))
  })
  default = null
}

variable "name" {
  description = "Name of the Backup Vault to create. Leave null if reusing an existing vault via `vault_reuse`."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "vault_config" {
  description = "Configuration for the Backup Vault. Only used if `vault_reuse` is null."
  type = object({
    description                                = optional(string, "Backup Vault managed by Terraform.")
    labels                                     = optional(map(string), {})
    annotations                                = optional(map(string), {})
    access_restriction                         = optional(string, "WITHIN_ORGANIZATION")
    backup_minimum_enforced_retention_duration = optional(string, "100000s")
    backup_retention_inheritance               = optional(string, "INHERIT_VAULT_RETENTION")
    force_update                               = optional(bool, false)
    ignore_inactive_datasources                = optional(bool, false)
    ignore_backup_plan_references              = optional(bool, false)
    allow_missing                              = optional(bool, false)
  })
  default = {}
}

variable "vault_reuse" {
  description = "Configuration to reuse an existing Backup Vault."
  type = object({
    vault_id   = string
    location   = optional(string)
    project_id = optional(string)
  })
  default = null
  validation {
    condition     = var.name == null || var.vault_reuse == null
    error_message = "name and vault_reuse can not be used together."
  }
}
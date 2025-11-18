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
variable "access_restriction" {
  description = "Access restriction policy for the vault. E.g., ACCESS_RESTRICTION_UNSPECIFIED, WITHIN_PROJECT, WITHIN_ORGANIZATION, UNRESTRICTED, or WITHIN_ORG_BUT_UNRESTRICTED_FOR_BA."
  type        = string
  default     = "WITHIN_ORGANIZATION"
  validation {
    condition = contains([
      "ACCESS_RESTRICTION_UNSPECIFIED",
      "WITHIN_PROJECT",
      "WITHIN_ORGANIZATION",
      "UNRESTRICTED",
      "WITHIN_ORG_BUT_UNRESTRICTED_FOR_BA"
    ], var.access_restriction)
    error_message = "The access_restriction value must be one of: ACCESS_RESTRICTION_UNSPECIFIED, WITHIN_PROJECT, WITHIN_ORGANIZATION, UNRESTRICTED, or WITHIN_ORG_BUT_UNRESTRICTED_FOR_BA."
  }
}

variable "allow_missing" {
  description = "If true, the request succeeds even if the Backup Vault does not exist. (Used for deletion/update operations)."
  type        = string
  default     = "false"
}

variable "annotations" {
  description = "User-defined key/value map of annotations. Required for certain features."
  type        = map(string)
  default     = {}
}

variable "backup_minimum_enforced_retention_duration" {
  description = "Minimum retention duration for backup data in the vault, specified in seconds (e.g., '100000s')."
  type        = string
  default     = "100000s"
}

variable "backup_plan_id" {
  description = "The resource ID of the Backup Plan."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.backup_plan_id))
    error_message = "The backup_plan_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "backup_plan_resource_type" {
  description = "The type of resource being backed up (e.g., 'compute.googleapis.com/Disk')."
  type        = string
  validation {
    condition = contains([
      "compute.googleapis.com/Instance",
      "compute.googleapis.com/Disk",
      "sqladmin.googleapis.com/Instance",
      "storage.googleapis.com/Bucket"
    ], var.backup_plan_resource_type)
    error_message = "The backup_plan_resource_type value must be of [ compute.googleapis.com/Instance, compute.googleapis.com/Disk, sqladmin.googleapis.com/Instance, storage.googleapis.com/Bucket ]"
  }
  default = "compute.googleapis.com/Instance"
}

variable "backup_retention_inheritance" {
  description = "Controls if the vault inherits retention from the backup plan or uses its own retention policy. E.g., 'INHERIT_VAULT_RETENTION' or 'NO_INHERITANCE'."
  type        = string
  default     = "INHERIT_VAULT_RETENTION"
}

variable "backup_rules" {
  description = "A list of backup rules, including schedules and retention."
  type = list(object({
    rule_id               = string
    backup_retention_days = number
    standard_schedule = object({
      recurrence_type  = string
      hourly_frequency = optional(number)
      days_of_week     = optional(list(string))
      days_of_month    = optional(list(number))
      months           = optional(list(string))
      time_zone        = string
      backup_window = object({
        start_hour_of_day = number
        end_hour_of_day   = number
      })
    })
  }))
}

variable "backup_vault_id" {
  description = "The resource ID of the Backup Vault. Must contain only lowercase letters, numbers, and hyphens."
  type        = string
  default     = null
  validation {
    condition     = var.backup_vault_id == null || can(regex("^[a-z0-9-]+$", var.backup_vault_id))
    error_message = "The backup_vault_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "backup_vault_create" {
  description = "If true, creates a new Backup Vault. If false, uses an existing Backup Vault specified by backup_vault_id."
  type        = bool
  default     = true
}

variable "force_update" {
  description = "Indicates if the resource should be force-updated."
  type        = string
  default     = "false"
}

variable "ignore_backup_plan_references" {
  description = "If true, allows deletion of the vault even if it's referenced by a backup plan."
  type        = string
  default     = "false"
}

variable "ignore_inactive_datasources" {
  description = "If true, allows deletion of the vault even if it contains inactive datasources."
  type        = string
  default     = "false"
}

variable "labels" {
  description = "User-defined key/value map of labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "The region of the Backup Vault."
  type        = string
}

variable "plan_description" {
  description = "Backup Plan."
  type        = string
  default     = "Backup Vault managed by Terraform."
}


variable "project_id" {
  description = "The ID of the GCP project in which resources will be created."
  type        = string
}

variable "vault_description" {
  description = "Backup Vault."
  type        = string
  default     = "Backup Vault managed by Terraform."
}
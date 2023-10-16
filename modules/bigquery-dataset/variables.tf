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

variable "access" {
  description = "Map of access rules with role and identity type. Keys are arbitrary and must match those in the `access_identities` variable, types are `domain`, `group`, `special_group`, `user`, `view`."
  type = map(object({
    role = string
    type = string
  }))
  default = {}
  validation {
    condition = can([
      for k, v in var.access :
      index(["domain", "group", "special_group", "user", "view"], v.type)
    ])
    error_message = "Access type must be one of 'domain', 'group', 'special_group', 'user', 'view'."
  }
}

variable "access_identities" {
  description = "Map of access identities used for basic access roles. View identities have the format 'project_id|dataset_id|table_id'."
  type        = map(string)
  default     = {}
}

variable "authorized_datasets" {
  description = "An array of datasets to be authorized on the dataset."
  type = list(object({
    dataset_id = string,
    project_id = string,
  }))
  default = []
}

variable "authorized_routines" {
  description = "An array of authorized routine to be authorized on the dataset."
  type = list(object({
    project_id = string,
    dataset_id = string,
    routine_id = string
  }))
  default = []
}

variable "authorized_views" {
  description = "An array of views to be authorized on the dataset."
  type = list(object({
    dataset_id = string,
    project_id = string,
    table_id   = string # this is the view id, but we keep table_id to stay consistent as the resource
  }))
  default = []
}

variable "dataset_access" {
  description = "Set access in the dataset resource instead of using separate resources."
  type        = bool
  default     = false
}

variable "description" {
  description = "Optional description."
  type        = string
  default     = "Terraform managed."
}

variable "encryption_key" {
  description = "Self link of the KMS key that will be used to protect destination table."
  type        = string
  default     = null
}

variable "friendly_name" {
  description = "Dataset friendly name."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format. Mutually exclusive with the access_* variables used for basic roles."
  type        = map(list(string))
  default     = {}
}

variable "id" {
  description = "Dataset id."
  type        = string
}

variable "labels" {
  description = "Dataset labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Dataset location."
  type        = string
  default     = "EU"
}

variable "materialized_views" {
  description = "Materialized views definitions."
  type = map(object({
    query                            = string
    allow_non_incremental_definition = optional(bool)
    deletion_protection              = optional(bool)
    description                      = optional(string, "Terraform managed.")
    enable_refresh                   = optional(bool)
    friendly_name                    = optional(string)
    labels                           = optional(map(string), {})
    refresh_interval_ms              = optional(bool)
    options = optional(object({
      clustering      = optional(list(string))
      expiration_time = optional(number)
    }), {})
    partitioning = optional(object({
      field = optional(string)
      range = optional(object({
        end      = number
        interval = number
        start    = number
      }))
      time = optional(object({
        type                     = string
        expiration_ms            = optional(number)
        field                    = optional(string)
        require_partition_filter = optional(bool)
      }))
    }))
  }))
  default = {}
}

variable "options" {
  description = "Dataset options."
  type = object({
    default_collation               = optional(string)
    default_table_expiration_ms     = optional(number)
    default_partition_expiration_ms = optional(number)
    delete_contents_on_destroy      = optional(bool, false)
    is_case_insensitive             = optional(bool)
    max_time_travel_hours           = optional(number, 168)
    storage_billing_model           = optional(string)
  })
  default = {}
}

variable "project_id" {
  description = "Id of the project where datasets will be created."
  type        = string
}

variable "tables" {
  description = "Table definitions. Options and partitioning default to null. Partitioning can only use `range` or `time`, set the unused one to null."
  type = map(object({
    deletion_protection = optional(bool)
    description         = optional(string, "Terraform managed.")
    friendly_name       = optional(string)
    labels              = optional(map(string), {})
    schema              = optional(string)
    options = optional(object({
      clustering      = optional(list(string))
      encryption_key  = optional(string)
      expiration_time = optional(number)
    }), {})
    partitioning = optional(object({
      field = optional(string)
      range = optional(object({
        end      = number
        interval = number
        start    = number
      }))
      time = optional(object({
        type                     = string
        expiration_ms            = optional(number)
        field                    = optional(string)
        require_partition_filter = optional(bool)
      }))
    }))
  }))
  default = {}
}

variable "views" {
  description = "View definitions."
  type = map(object({
    query               = string
    deletion_protection = optional(bool)
    description         = optional(string, "Terraform managed.")
    friendly_name       = optional(string)
    labels              = optional(map(string), {})
    use_legacy_sql      = optional(bool)
  }))
  default = {}
}

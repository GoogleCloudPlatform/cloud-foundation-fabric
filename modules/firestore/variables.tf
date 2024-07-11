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

variable "backup_schedule" {
  description = "Backup schedule."
  type = object({
    retention         = string
    daily_recurrence  = optional(bool, false)
    weekly_recurrence = optional(string)
  })
  default = null

  validation {
    condition = (var.backup_schedule == null ? true :
    can(regex("\\d+s", var.backup_schedule.retention)))
    error_message = "Retention must be specified in the following format: \\d+s."
  }
  validation {
    condition = (var.backup_schedule == null ? true :
      (var.backup_schedule.daily_recurrence
      && var.backup_schedule.weekly_recurrence == null) ||
      (!var.backup_schedule.daily_recurrence
    && var.backup_schedule.weekly_recurrence != null))
    error_message = "Either daily_recurrence or weekly_recurrence must be specified, but not both."
  }
}

variable "database" {
  description = "Database attributes."
  type = object({
    app_engine_integration_mode       = optional(string)
    concurrency_mode                  = optional(string)
    deletion_policy                   = optional(string)
    delete_protection_state           = optional(string)
    kms_key_name                      = optional(string)
    location_id                       = optional(string)
    name                              = string
    point_in_time_recovery_enablement = optional(string)
    type                              = optional(string)
  })
  validation {
    condition = (try(var.database.app_engine_integration_mode, null) == null ? true : contains([
      "ENABLED",
      "DISABLED",
    ], var.database.app_engine_integration_mode))
    error_message = "Invalid app_engine_integration_mode. If set, possible values are: ENABLED, DISABLE."
  }
  validation {
    condition = (try(var.database.concurrency_mode, null) == null ? true : contains([
      "OPTIMISTIC",
      "PESSIMISTIC",
      "OPTIMISTIC_WITH_ENTITY_GROUPS"
    ], var.database.concurrency_mode))
    error_message = "Invalid concurrency_mode. If set, possible values are: OPTIMISTIC, PESIMISTIC, OPTIMISTIC_WITH_ENTITY_GROUPS."
  }
  validation {
    condition = (try(var.database.deletion_policy, null) == null ? true : contains([
      "ABANDON",
      "DELETE"
    ], var.database.deletion_policy))
    error_message = "Invalid deletion_policy. If set, possible values are: ABANDON, DELETE."
  }
  validation {
    condition = (try(var.database.deletion_protection_state, null) == null ? true : contains([
      "DELETE_PROTECTION_STATE_UNSPECIFIED",
      "DELETE_PROTECTION_ENABLED",
      "DELETE_PROTECTION_DISABLED"
    ], var.database.deletion_protection_state))
    error_message = "Invalid delete_protection_state. If set, possible values are: DELETE_PROTECTION_STATE_UNSPECIFIED, DELETE_PROTECTION_ENABLED, DELETE_PROTECTION_DISABLED."
  }

  validation {
    condition = (try(var.database.point_in_time_recovery_enablement, null) == null ? true : contains([
      "POINT_IN_TIME_RECOVERY_ENABLED",
      "POINT_IN_TIME_RECOVERY_DISABLED"
    ], var.database.point_in_time_recovery_enablement))
    error_message = "Invalid point_in_time_recovery_enablement. If set, possible values are: POINT_IN_TIME_RECOVERY_ENABLED, POINT_IN_TIME_RECOVERY_DISABLED."
  }

}

variable "database_create" {
  description = "Flag indicating whether the database should be created of not."
  type        = string
  default     = true
}

variable "documents" {
  description = "Documents."
  type = map(object({
    collection  = string
    document_id = string
    fields      = any
  }))
  default  = {}
  nullable = false
}

variable "fields" {
  description = "Fields."
  type = map(object({
    collection = string
    field      = string
    indexes = optional(list(object({
      query_scope  = optional(string)
      order        = optional(string)
      array_config = optional(string)
    })))
    ttl_config = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([for v1 in var.fields :
      v1.indexes == null ? true : alltrue([for v2 in coalesce(v1.indexes, []) :
        v2.query_scope == null ? true : contains([
          "COLLECTION",
          "COLLECTION_GROUP"
    ], v2.query_scope)])])
    error_message = "Invalid query_scope. If set possible values are: COLLECTION, COLLECTION_GROUP."
  }

  validation {
    condition = alltrue([for v1 in var.fields :
      v1.indexes == null ? true : alltrue([for v2 in coalesce(v1.indexes, []) :
        v2.order == null ? true : contains([
          "ASCENDING",
          "DESCENDING"
    ], v2.order)])])
    error_message = "Invalid order. If set possible values are: COLLECTION, COLLECTION_GROUP."
  }

  validation {
    condition = alltrue([for v1 in var.fields :
      v1.indexes == null ? true : alltrue([for v2 in coalesce(v1.indexes, []) :
    v2.array_config == null || v2.array_config == "CONTAINS"])])
    error_message = "Invalid array_config, value must be equal to CONTAINS."
  }


  validation {
    condition = alltrue([for v1 in var.fields :
      v1.indexes == null ? true : alltrue([for v2 in coalesce(v1.indexes, []) :
    !(v2.order != null && v2.array_config != null)])])
    error_message = "Either order or array_config should be specified, but not both."
  }

}

variable "indexes" {
  description = "Indexes."
  type = map(object({
    api_scope  = optional(string)
    collection = string
    fields = list(object({
      field_path   = optional(string)
      order        = optional(string)
      array_config = optional(string)
      vector_config = optional(object({
        dimension = optional(number)
        flat      = optional(bool)
      }))
    }))
    query_scope = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([for k, v in var.indexes : v.api_scope == null ? true : contains([
      "ANY_API",
      "DATASTORE_MODE_API"
      ], v.api_scope)
    ])
    error_message = "Invalid api_scope. If set possible values are: ANY_API, DATASTORE_MODE_API."
  }

  validation {
    condition = alltrue([for k, v in var.indexes : v.query_scope == null ? true : contains([
      "COLLECTION",
      "COLLECTION_GROUP",
      "COLLECTION_RECURSIVE"
      ], v.query_scope)
    ])
    error_message = "Invalid query_scope. If set possible values are: COLLECTION, COLLECTION_GROUP, COLLECTION_RECURSIVE."
  }

  validation {
    condition = alltrue([for k1, v1 in var.indexes :
      v1.fields == null ? true : alltrue([for v2 in coalesce(v1.fields, []) :
        v2.order == null ? true : contains([
          "ASCENDING",
          "DESCENDING"
    ], v2.order)])])
    error_message = "Invalid order. If set possible values are: COLLECTION, COLLECTION_GROUP."
  }

  validation {
    condition = alltrue([for k1, v1 in var.indexes :
      v1.fields == null ? true : alltrue([for v2 in coalesce(v1.fields, []) :
    v2.array_config == null || v2.array_config == "CONTAINS"])])
    error_message = "Invalid array_config, value must be equal to CONTAINS."
  }

  validation {
    condition = alltrue([for k1, v1 in var.indexes :
      v1.fields == null ? true : alltrue([for v2 in coalesce(v1.fields, []) :
    length([for v3 in [v2.order != null, v2.array_config != null, v2.vector_config != null] : v3 if v3]) == 1])])
    error_message = "Only one of order, array_config or vector_config can be specified."
  }

}

variable "project_id" {
  description = "Project id."
  type        = string
}

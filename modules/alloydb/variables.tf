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

variable "annotations" {
  description = "Map FLAG_NAME=>VALUE for annotations which allow client tools to store small amount of arbitrary data."
  type        = map(string)
  default     = null
}

variable "automated_backup_configuration" {
  description = "Automated backup settings for cluster."
  nullable    = false
  type = object({
    enabled       = optional(bool, false)
    backup_window = optional(string, "1800s")
    location      = optional(string)
    weekly_schedule = optional(object({
      days_of_week = optional(list(string), [
        "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
      ])
      start_times = optional(object({
        hours   = optional(number, 23)
        minutes = optional(number, 0)
        seconds = optional(number, 0)
        nanos   = optional(number, 0)
      }), {})
    }), {})
    retention_count  = optional(number, 7)
    retention_period = optional(string, null)
  })
  default = {
    enabled       = false
    backup_window = "1800s"
    location      = null
    weekly_schedule = {
      days_of_week = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
      start_times = {
        hours   = 23
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
    retention_count  = 7
    retention_period = null
  }
  validation {
    condition = (
      var.automated_backup_configuration.enabled ? (
        # Maintenance window validation below
        !(var.automated_backup_configuration.retention_count != null && var.automated_backup_configuration.retention_period != null) &&
        # Maintenance window day validation
        length([
          for day in var.automated_backup_configuration.weekly_schedule.days_of_week : true
          if contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], day)
        ]) == length(var.automated_backup_configuration.weekly_schedule.days_of_week)
      ) : true
    )
    error_message = "Days of week must contains one or more days with the following format 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'. You can only specify retention_count or retention_period."
  }
}

variable "availability_type" {
  description = "Availability type for the primary replica. Either `ZONAL` or `REGIONAL`."
  type        = string
  default     = "REGIONAL"
}

variable "client_connection_config" {
  description = "Client connection config."
  type = object({
    require_connectors = optional(bool, false)
    ssl_config = optional(object({
      ssl_mode = string
    }), null)
  })
  default = null
}

variable "cluster_display_name" {
  description = "Display name of the primary cluster."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the primary cluster."
  type        = string
}

variable "continuous_backup_configuration" {
  description = "Continuous backup settings for cluster."
  nullable    = true
  type = object({
    enabled              = optional(bool, false)
    recovery_window_days = optional(number, 14)
  })
  default = {
    enabled              = true
    recovery_window_days = 14
  }
}

variable "cross_region_replication" {
  description = "Cross region replication config."
  type = object({
    enabled                         = optional(bool, false)
    promote_secondary               = optional(bool, false)
    region                          = optional(string, null)
    secondary_cluster_display_name  = optional(string, null)
    secondary_cluster_name          = optional(string, null)
    secondary_instance_display_name = optional(string, null)
    secondary_instance_name         = optional(string, null)
  })
  default = {}
  validation {
    condition     = !var.cross_region_replication.enabled || var.cross_region_replication.enabled && var.cross_region_replication.region != null
    error_message = "Region must be available when cross region replication is enabled."
  }
}

variable "database_version" {
  description = "Database type and version to create."
  type        = string
  default     = "POSTGRES_15"
}

variable "deletion_policy" {
  description = "AlloyDB cluster and instance deletion policy."
  type        = string
  default     = null
}

variable "display_name" {
  description = "AlloyDB instance display name."
  type        = string
  default     = null
}

variable "encryption_config" {
  description = "Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'."
  type = object({
    primary_kms_key_name   = string
    secondary_kms_key_name = optional(string, null)
  })
  default  = null
  nullable = true
}

variable "flags" {
  description = "Map FLAG_NAME=>VALUE for database-specific tuning."
  type        = map(string)
  default     = null
}

variable "gce_zone" {
  description = "The GCE zone that the instance should serve from. This can ONLY be specified for ZONAL instances. If present for a REGIONAL instance, an error will be thrown."
  type        = string
  default     = null
}

variable "initial_user" {
  description = "AlloyDB cluster initial user credentials."
  type = object({
    user     = optional(string, "root")
    password = string
  })
  default = null
}

variable "instance_name" {
  description = "Name of primary instance."
  type        = string
}

variable "labels" {
  description = "Labels to be attached to all instances."
  type        = map(string)
  default     = null
}

variable "location" {
  description = "Region or zone of the cluster and instance."
  type        = string
}

variable "machine_config" {
  description = "AlloyDB machine config."
  type = object({
    cpu_count = optional(number, 2)
  })
  nullable = false
  default = {
    cpu_count = 2
  }
}

variable "maintenance_config" {
  description = "Set maintenance window configuration."
  type = object({
    enabled = optional(bool, false)
    day     = optional(string, "SUNDAY")
    start_time = optional(object({
      hours   = optional(number, 23)
      minutes = optional(number, 0)
      seconds = optional(number, 0)
      nanos   = optional(number, 0)
    }), {})
  })
  default = {
    enabled = false
    day     = "SUNDAY"
    start_time = {
      hours   = 23
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  validation {
    condition = (
      var.maintenance_config.enabled ? (
        # Maintenance window validation below
        var.maintenance_config.start_time.hours >= 0 &&
        var.maintenance_config.start_time.hours <= 23 &&
        var.maintenance_config.start_time.minutes == 0 &&
        var.maintenance_config.start_time.seconds == 0 &&
        var.maintenance_config.start_time.nanos == 0 &&
        # Maintenance window day validation
        contains([
          "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
      ], var.maintenance_config.day)) : true
    )
    error_message = "Maintenance window day must one of 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'. Maintenance window hour must be between 0 and 23 and maintenance window minutes, seconds and nanos should be 0."
  }
}

variable "network_config" {
  description = "Network configuration for cluster and instance. Only one between psa_config and psc_config can be used."
  type = object({
    psa_config = optional(object({
      network                      = optional(string)
      allocated_ip_range           = optional(string)
      authorized_external_networks = optional(list(string), [])
      enable_public_ip             = optional(bool, false)
    }))
    psc_config = optional(object({
      allowed_consumer_projects = optional(list(string), [])
    }), null)
  })
  nullable = false
  validation {
    condition = (
      var.network_config.psa_config == null || (
        (
          try(var.network_config.psa_config.enable_public_ip, false) &&
          try(length(var.network_config.psa_config.authorized_external_networks), 0) > 0
          ) || (
          try(length(var.network_config.psa_config.authorized_external_networks), 0) == 0
        )
      )
    )
    error_message = "A list of external network authorized to access this instance is required only in case public ip is enabled for the instance."
  }
  validation {
    condition     = (var.network_config.psc_config == null) != (var.network_config.psa_config == null)
    error_message = "Please specify either psa_config or psc_config."
  }
}

variable "prefix" {
  description = "Optional prefix used to generate instance names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "The ID of the project where this instances will be created."
  type        = string
}

variable "query_insights_config" {
  description = "Query insights config."
  type = object({
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, true)
    record_client_address   = optional(bool, true)
    query_plans_per_minute  = optional(number, 5)
  })
  default = {
    query_string_length     = 1024
    record_application_tags = true
    record_client_address   = true
    query_plans_per_minute  = 5
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this service, in key => tag value id format."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "users" {
  description = "Map of users to create in the primary instance (and replicated to other replicas). Set PASSWORD to null if you want to get an autogenerated password. The user types available are: 'ALLOYDB_BUILT_IN' or 'ALLOYDB_IAM_USER'."
  type = map(object({
    password = optional(string)
    roles    = optional(list(string), ["alloydbsuperuser"])
    type     = optional(string)
  }))
  default = null
  validation {
    condition = alltrue([
      for user in coalesce(var.users, {}) :
      try(contains(["ALLOYDB_BUILT_IN", "ALLOYDB_IAM_USER"], user.type), true)
    ])
    error_message = "User type must one of 'ALLOYDB_BUILT_IN', 'ALLOYDB_IAM_USER'"
  }
}

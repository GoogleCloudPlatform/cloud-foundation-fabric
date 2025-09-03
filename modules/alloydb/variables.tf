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
  type = object({
    enabled       = optional(bool, false)
    backup_window = optional(string, "1800s")
    location      = optional(string)
    weekly_schedule = optional(object({
      days_of_week = optional(list(string), [
        "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
      ])
      start_times = optional(object({
        hours = optional(number, 23)
      }), {})
    }), {})
    retention_count  = optional(number, 7)
    retention_period = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      var.automated_backup_configuration.enabled ? (
        # Backup window validation below
        !(var.automated_backup_configuration.retention_count != null && var.automated_backup_configuration.retention_period != null) &&
        # Backup window hours below
        var.automated_backup_configuration.weekly_schedule.start_times.hours >= 0 &&
        var.automated_backup_configuration.weekly_schedule.start_times.hours <= 23 &&
        # Backup window day validation
        setintersection(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], var.automated_backup_configuration.weekly_schedule.days_of_week) == toset(var.automated_backup_configuration.weekly_schedule.days_of_week)
      ) : true
    )
    error_message = "Days of week must contains one or more days with the following format 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'. Backup window hour must be between 0 and 23. You can only specify retention_count or retention_period."
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
    }))
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
  nullable    = false
}

variable "continuous_backup_configuration" {
  description = "Continuous backup settings for cluster."
  type = object({
    enabled              = optional(bool, true)
    recovery_window_days = optional(number, 14)
  })
  nullable = false
  default  = {}
}

variable "cross_region_replication" {
  description = "Cross region replication config."
  type = object({
    enabled                         = optional(bool, false)
    promote_secondary               = optional(bool, false)
    switchover_mode                 = optional(bool, false)
    region                          = optional(string)
    secondary_cluster_display_name  = optional(string)
    secondary_cluster_name          = optional(string)
    secondary_instance_display_name = optional(string)
    secondary_instance_name         = optional(string)
    secondary_machine_config = optional(object({
      cpu_count    = number
      machine_type = optional(string)
    }))
  })
  default  = {}
  nullable = false
  validation {
    condition     = !var.cross_region_replication.enabled || var.cross_region_replication.enabled && var.cross_region_replication.region != null
    error_message = "Region must be available when cross region replication is enabled."
  }
  validation {
    condition     = !(var.cross_region_replication.switchover_mode && var.cross_region_replication.promote_secondary)
    error_message = "Please choose to either promote secondary cluster or align an existing cluster after switchover."
  }
  validation {
    condition     = contains([2, 4, 8, 16, 32, 64, 96, 128], try(var.cross_region_replication.secondary_machine_config.cpu_count, 2))
    error_message = "The number of CPU's in the VM instance must be one of [2, 4, 8, 16, 32, 64, 96, 128]"
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

variable "deletion_protection" {
  description = "Whether Terraform will be prevented from destroying the cluster. When the field is set to true or unset in Terraform state, a terraform apply or terraform destroy that would delete the cluster will fail. When the field is set to false, deleting the cluster is allowed."
  type        = bool
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
    secondary_kms_key_name = optional(string)
  })
  default = null
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
    user     = optional(string, "postgres")
    password = string
  })
  default = null
}

variable "instance_name" {
  description = "Name of primary instance."
  type        = string
  nullable    = false
}

variable "labels" {
  description = "Labels to be attached to all instances."
  type        = map(string)
  default     = null
}

variable "location" {
  description = "Region or zone of the cluster and instance."
  type        = string
  nullable    = false
}

variable "machine_config" {
  description = "AlloyDB machine config."
  type = object({
    cpu_count    = optional(number, 2)
    machine_type = optional(string)
  })
  nullable = false
  default  = {}
  validation {
    condition     = contains([2, 4, 8, 16, 32, 64, 96, 128], var.machine_config.cpu_count)
    error_message = "The number of CPU's in the VM instance must be one of [2, 4, 8, 16, 32, 64, 96, 128]"
  }
}

variable "maintenance_config" {
  description = "Set maintenance window configuration."
  type = object({
    enabled = optional(bool, false)
    day     = optional(string, "SUNDAY")
    start_time = optional(object({
      hours = optional(number, 23)
    }), {})
  })
  default = {}
  validation {
    condition = (
      var.maintenance_config.enabled ? (
        # Maintenance window validation below
        var.maintenance_config.start_time.hours >= 0 &&
        var.maintenance_config.start_time.hours <= 23 &&
        # Maintenance window day validation
        contains([
          "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
      ], var.maintenance_config.day)) : true
    )
    error_message = "Maintenance window day must one of 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'. Maintenance window hour must be between 0 and 23."
  }
}

variable "network_config" {
  description = "Network configuration for cluster and instance. Only one between psa_config and psc_config can be used."
  type = object({
    psa_config = optional(object({
      network                      = string
      allocated_ip_range           = optional(string)
      authorized_external_networks = optional(list(string), [])
      enable_public_ip             = optional(bool, false)
      enable_outbound_public_ip    = optional(bool, false)
    }))
    psc_config = optional(object({
      allowed_consumer_projects = list(string)
    }))
  })
  nullable = false
  validation {
    condition     = try(length(var.network_config.psa_config.authorized_external_networks) > 0, false) ? try(var.network_config.psa_config.enable_public_ip, false) : true
    error_message = "A list of external network authorized to access this instance is required only in case public IP is enabled for the instance."
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

variable "project_number" {
  description = "The project number of the project where this instances will be created. Only used for testing purposes."
  type        = string
  default     = null
}

variable "query_insights_config" {
  description = "Query insights config."
  type = object({
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, true)
    record_client_address   = optional(bool, true)
    query_plans_per_minute  = optional(number, 5)
  })
  default = {}
}

variable "read_pool" {
  description = "Map of read pool instances to create in the primary cluster."
  type = map(object({
    display_name = optional(string)
    node_count   = optional(number, 1)
    flags        = optional(map(string))
    client_connection_config = optional(object({
      require_connectors = optional(bool, false)
      ssl_config = optional(object({
        ssl_mode = string
      }))
    }))
    machine_config = optional(object({
      cpu_count    = optional(number, 2)
      machine_type = optional(string)
    }), {})
    network_config = optional(object({
      authorized_external_networks = optional(list(string), [])
      enable_public_ip             = optional(bool, false)
    }), {})
    query_insights_config = optional(object({
      query_string_length     = optional(number, 1024)
      record_application_tags = optional(bool, true)
      record_client_address   = optional(bool, true)
      query_plans_per_minute  = optional(number, 5)
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.read_pool :
      contains([2, 4, 8, 16, 32, 64, 96, 128], v.machine_config.cpu_count)
    ])
    error_message = "The number of CPU's in the VM instance must be one of [2, 4, 8, 16, 32, 64, 96, 128]"
  }
  validation {
    condition = alltrue([
      for k, v in var.read_pool :
      try(length(v.network_config.psa_config.authorized_external_networks) > 0, false) ? try(v.network_config.psa_config.enable_public_ip, false) : true
    ])
    error_message = "A list of external network authorized to access this replica pool instance is required only in case public IP is enabled for the replica pool instance."
  }
}

variable "skip_await_major_version_upgrade" {
  description = "Set to true to skip awaiting on the major version upgrade of the cluster."
  type        = bool
  default     = true
}

variable "subscription_type" {
  description = "The subscription type of cluster. Possible values are: 'STANDARD' or 'TRIAL'."
  type        = string
  default     = "STANDARD"
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
    type     = optional(string, "ALLOYDB_BUILT_IN")
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for user in var.users :
      contains(["ALLOYDB_BUILT_IN", "ALLOYDB_IAM_USER"], user.type)
    ])
    error_message = "User type must one of 'ALLOYDB_BUILT_IN', 'ALLOYDB_IAM_USER'."
  }
}

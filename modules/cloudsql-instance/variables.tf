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
variable "activation_policy" {
  description = "This variable specifies when the instance should be active. Can be either ALWAYS, NEVER or ON_DEMAND. Default is ALWAYS."
  type        = string
  default     = "ALWAYS"
  validation {
    condition     = var.activation_policy == "NEVER" || var.activation_policy == "ON_DEMAND" || var.activation_policy == "ALWAYS"
    error_message = "The variable activation_policy must be ALWAYS, NEVER or ON_DEMAND."
  }
  nullable = false
}

variable "availability_type" {
  description = "Availability type for the primary replica. Either `ZONAL` or `REGIONAL`."
  type        = string
  default     = "ZONAL"
}

variable "backup_configuration" {
  description = "Backup settings for primary instance. Will be automatically enabled if using MySQL with one or more replicas."
  nullable    = false
  type = object({
    enabled                        = optional(bool, false)
    binary_log_enabled             = optional(bool, false)
    start_time                     = optional(string, "23:00")
    location                       = optional(string)
    log_retention_days             = optional(number, 7)
    point_in_time_recovery_enabled = optional(bool)
    retention_count                = optional(number, 7)
  })
  default = {
    enabled                        = false
    binary_log_enabled             = false
    start_time                     = "23:00"
    location                       = null
    log_retention_days             = 7
    point_in_time_recovery_enabled = null
    retention_count                = 7
  }
}

variable "collation" {
  description = "The name of server instance collation."
  type        = string
  default     = null
}

variable "connector_enforcement" {
  description = "Specifies if connections must use Cloud SQL connectors."
  type        = string
  default     = null
}

variable "data_cache" {
  description = "Enable data cache. Only used for Enterprise MYSQL and PostgreSQL."
  type        = bool
  nullable    = false
  default     = false
}

variable "database_version" {
  description = "Database type and version to create."
  type        = string
}

variable "databases" {
  description = "Databases to create once the primary instance is created."
  type        = list(string)
  default     = null
}

variable "disk_autoresize_limit" {
  description = "The maximum size to which storage capacity can be automatically increased. The default value is 0, which specifies that there is no limit."
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "Disk size in GB. Set to null to enable autoresize."
  type        = number
  default     = null
}

variable "disk_type" {
  description = "The type of data disk: `PD_SSD` or `PD_HDD`."
  type        = string
  default     = "PD_SSD"
}

variable "edition" {
  description = "The edition of the instance, can be ENTERPRISE or ENTERPRISE_PLUS."
  type        = string
  default     = "ENTERPRISE"
}

variable "encryption_key_name" {
  description = "The full path to the encryption key used for the CMEK disk encryption of the primary instance."
  type        = string
  default     = null
}

variable "flags" {
  description = "Map FLAG_NAME=>VALUE for database-specific tuning."
  type        = map(string)
  default     = null
}

variable "gcp_deletion_protection" {
  description = "Set Google's deletion protection attribute which applies across all surfaces (UI, API, & Terraform)."
  type        = bool
  default     = true
  nullable    = false
}

variable "insights_config" {
  description = "Query Insights configuration. Defaults to null which disables Query Insights."
  type = object({
    query_string_length     = optional(number, 1024)
    record_application_tags = optional(bool, false)
    record_client_address   = optional(bool, false)
    query_plans_per_minute  = optional(number, 5)
  })
  default = null
}

variable "labels" {
  description = "Labels to be attached to all instances."
  type        = map(string)
  default     = null
}

variable "maintenance_config" {
  description = "Set maintenance window configuration and maintenance deny period (up to 90 days). Date format: 'yyyy-mm-dd'."
  type = object({
    maintenance_window = optional(object({
      day          = number
      hour         = number
      update_track = optional(string, null)
    }), null)
    deny_maintenance_period = optional(object({
      start_date = string
      end_date   = string
      start_time = optional(string, "00:00:00")
    }), null)
  })
  default = {}
  validation {
    condition = (
      try(var.maintenance_config.maintenance_window, null) == null ? true : (
        # Maintenance window day validation below
        var.maintenance_config.maintenance_window.day >= 1 &&
        var.maintenance_config.maintenance_window.day <= 7 &&
        # Maintenance window hour validation below
        var.maintenance_config.maintenance_window.hour >= 0 &&
        var.maintenance_config.maintenance_window.hour <= 23 &&
        # Maintenance window update_track validation below
        try(var.maintenance_config.maintenance_window.update_track, null) == null ? true :
        contains(["canary", "stable"], var.maintenance_config.maintenance_window.update_track)
      )
    )
    error_message = "Maintenance window day must be between 1 and 7, maintenance window hour must be between 0 and 23 and maintenance window update_track must be 'stable' or 'canary'."
  }
}

variable "name" {
  description = "Name of primary instance."
  type        = string
}

variable "network_config" {
  description = "Network configuration for the instance. Only one between private_network and psc_config can be used."
  type = object({
    authorized_networks = optional(map(string))
    connectivity = object({
      public_ipv4 = optional(bool, false)
      psa_config = optional(object({
        private_network = string
        allocated_ip_ranges = optional(object({
          primary = optional(string)
          replica = optional(string)
        }))
      }))
      psc_allowed_consumer_projects = optional(list(string))
    })
  })
  validation {
    condition     = (var.network_config.connectivity.psa_config != null ? 1 : 0) + (var.network_config.connectivity.psc_allowed_consumer_projects != null ? 1 : 0) < 2
    error_message = "Only one between private network and psc can be specified."
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

variable "region" {
  description = "Region of the primary instance."
  type        = string
}

variable "replicas" {
  description = "Map of NAME=> {REGION, KMS_KEY} for additional read replicas. Set to null to disable replica creation."
  type = map(object({
    region              = string
    encryption_key_name = optional(string)
  }))
  default = {}
}

variable "root_password" {
  description = "Root password of the Cloud SQL instance. Required for MS SQL Server."
  type        = string
  default     = null
}

variable "ssl" {
  description = "Setting to enable SSL, set config and certificates."
  type = object({
    client_certificates = optional(list(string))
    # More details @ https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#ssl_mode
    ssl_mode = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition     = var.ssl.ssl_mode == null || var.ssl.ssl_mode == "ALLOW_UNENCRYPTED_AND_ENCRYPTED" || var.ssl.ssl_mode == "ENCRYPTED_ONLY" || var.ssl.ssl_mode == "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    error_message = "The variable ssl_mode can be ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY for all, or TRUSTED_CLIENT_CERTIFICATE_REQUIRED for PostgreSQL or MySQL."
  }
}

variable "terraform_deletion_protection" {
  description = "Prevent terraform from deleting instances."
  type        = bool
  default     = true
  nullable    = false
}

variable "tier" {
  description = "The machine type to use for the instances."
  type        = string
}

variable "time_zone" {
  description = "The time_zone to be used by the database engine (supported only for SQL Server), in SQL Server timezone format."
  type        = string
  default     = null
}

variable "users" {
  description = "Map of users to create in the primary instance (and replicated to other replicas). For MySQL, anything after the first `@` (if present) will be used as the user's host. Set PASSWORD to null if you want to get an autogenerated password. The user types available are: 'BUILT_IN', 'CLOUD_IAM_USER' or 'CLOUD_IAM_SERVICE_ACCOUNT'."
  type = map(object({
    password = optional(string)
    type     = optional(string)
  }))
  default = null
}

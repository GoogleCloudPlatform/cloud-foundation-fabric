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

variable "allocated_ip_ranges" {
  description = "(Optional)The name of the allocated ip range for the private ip CloudSQL instance. For example: \"google-managed-services-default\". If set, the instance ip will be created in the allocated range. The range name must comply with RFC 1035. Specifically, the name must be 1-63 characters long and match the regular expression a-z?."
  type = object({
    primary = optional(string)
    replica = optional(string)
  })
  default  = {}
  nullable = false
}
variable "authorized_networks" {
  description = "Map of NAME=>CIDR_RANGE to allow to connect to the database(s)."
  type        = map(string)
  default     = null
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

variable "database_version" {
  description = "Database type and version to create."
  type        = string
}

variable "databases" {
  description = "Databases to create once the primary instance is created."
  type        = list(string)
  default     = null
}

variable "deletion_protection" {
  description = "Allow terraform to delete instances."
  type        = bool
  default     = false
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

variable "ipv4_enabled" {
  description = "Add a public IP address to database instance."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to be attached to all instances."
  type        = map(string)
  default     = null
}

variable "name" {
  description = "Name of primary instance."
  type        = string
}

variable "network" {
  description = "VPC self link where the instances will be deployed. Private Service Networking must be enabled and configured in this VPC."
  type        = string
}

variable "postgres_client_certificates" {
  description = "Map of cert keys connect to the application(s) using public IP."
  type        = list(string)
  default     = null
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
    encryption_key_name = string
  }))
  default = {}
}

variable "root_password" {
  description = "Root password of the Cloud SQL instance. Required for MS SQL Server."
  type        = string
  default     = null
}

variable "tier" {
  description = "The machine type to use for the instances."
  type        = string
}

variable "users" {
  description = "Map of users to create in the primary instance (and replicated to other replicas) in the format USER=>PASSWORD. For MySQL, anything afterr the first `@` (if persent) will be used as the user's host. Set PASSWORD to null if you want to get an autogenerated password."
  type        = map(string)
  default     = null
}

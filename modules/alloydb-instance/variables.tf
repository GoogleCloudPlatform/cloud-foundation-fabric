/**
 * Copyright 2023 Google LLC
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

variable "automated_backup_policy" {
  description = "The automated backup policy for this cluster."
  type = object({
    location      = optional(string)
    backup_window = optional(string)
    enabled       = optional(bool)
    weekly_schedule = optional(object({
      days_of_week = optional(list(string))
      start_times  = list(string)
    })),
    quantity_based_retention_count = optional(number)
    time_based_retention_count     = optional(string)
    labels                         = optional(map(string))
    backup_encryption_key_name     = optional(string)
  })
  default = null
}

variable "cluster_id" {
  description = "The ID of the alloydb cluster."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_id))
    error_message = "ERROR: Cluster ID must contain only Letters(lowercase), number, and hyphen."
  }
}

variable "display_name" {
  description = "Human readable display name for the Alloy DB Cluster."
  type        = string
  default     = null
}

variable "encryption_key_name" {
  description = "The fully-qualified resource name of the KMS key for cluster encryption."
  type        = string
  default     = null
}

variable "initial_user" {
  description = "Alloy DB Cluster Initial User Credentials."
  type = object({
    user     = optional(string),
    password = string
  })
  default = null
}

variable "labels" {
  description = "User-defined labels for the alloydb cluster."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Location where AlloyDb cluster will be deployed."
  type        = string
  default     = "europe-west2"
}

variable "network_name" {
  description = "The network name of the project in which to provision resources."
  type        = string
  default     = "multiple-readpool"
}

variable "network_self_link" {
  description = "Network ID where the AlloyDb cluster will be deployed."
  type        = string
}

variable "primary_instance_config" {
  description = "Primary cluster configuration that supports read and write operations."
  type = object({
    instance_id       = string,
    display_name      = optional(string),
    database_flags    = optional(map(string))
    labels            = optional(map(string))
    annotations       = optional(map(string))
    gce_zone          = optional(string)
    availability_type = optional(string)
    machine_cpu_count = optional(number, 2),
  })
  validation {
    condition     = can(regex("^(2|4|8|16|32|64)$", var.primary_instance_config.machine_cpu_count))
    error_message = "cpu count must be one of [2 4 8 16 32 64]."
  }
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.primary_instance_config.instance_id))
    error_message = "Primary Instance ID should satisfy the following pattern ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$."
  }
}

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "read_pool_instance" {
  description = "List of Read Pool Instances to be created."
  type = list(object({
    instance_id       = string
    display_name      = string
    node_count        = optional(number, 1)
    database_flags    = optional(map(string))
    availability_type = optional(string)
    gce_zone          = optional(string)
    machine_cpu_count = optional(number, 2)
  }))
  default = []
}

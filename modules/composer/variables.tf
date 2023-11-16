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

variable "allowed_ip_range" {
  description = "The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions are applied. For Cloud Composer 1 only."
  type = object({
    value       = string
    description = string
  })
  default = null
}

variable "database_config" {
  description = "The configuration settings for Cloud SQL instance used internally by Apache Airflow software. For Cloud Composer 1 only."
  type = object({
    machine_type = string
  })
  default = null
}

variable "encryption_config" {
  description = "The encryption options for the Cloud Composer environment and its dependencies."
  type = object({
    kms_key_name = string
  })
  default = null
}

variable "environment_size" {
  description = "The environment size controls the performance parameters of the managed Cloud Composer infrastructure that includes the Airflow database. Values for environment size are ENVIRONMENT_SIZE_SMALL, ENVIRONMENT_SIZE_MEDIUM, and ENVIRONMENT_SIZE_LARGE."
  type        = string
  default     = "ENVIRONMENT_SIZE_SMALL"
}

variable "maintenance_window" {
  description = "The configuration settings for Cloud Composer maintenance windows. BETA FOR Cloud Composer 1."
  type = object({
    start_time = string
    end_time   = string
    recurrence = string
  })
  default = null
}

variable "master_authorized_networks_config" {
  description = "Configuration options for the master authorized networks feature. Enabled master authorized networks will disallow all external traffic to access Kubernetes master through HTTPS except traffic from the given CIDR blocks, Google Compute Engine Public IPs and Google Prod IPs."
  type = object({
    display_name = bool
    cidr_blocks = object({
      display_name = optional(string)
      cidr_block   = string
    })
  })
  default = null
}

variable "name" {
  description = "Name of the environment."
  type        = string
}

variable "node_config" {
  description = "The configuration used for the Kubernetes Engine cluster."
  type = object({
    zone            = optional(string)
    machine_type    = optional(string)
    network         = optional(string)
    subnetwork      = optional(string)
    disk_size_gb    = optional(number)
    oauth_scopes    = optional(list(string))
    service_account = optional(string)
    tags            = optional(list(string))
    ip_allocation_policy = optional(list(object({
      use_ip_aliases                = bool
      cluster_secondary_range_name  = optional(string)
      services_secondary_range_name = optional(string)
      cluster_ipv4_cidr_block       = optional(string)
      services_ipv4_cidr_block      = optional(string)
    })))
    enable_ip_masq_agent = optional(bool)
  })
  default = null
}

variable "node_count" {
  description = "The number of nodes in the Kubernetes Engine cluster of the environment. For Cloud Composer 1 only."
  type        = number
  default     = 3
}

variable "private_environment_config" {
  description = "The configuration used for the Private IP Cloud Composer environment."
  type = object({
    connection_type                  = optional(string)
    enable_private_endpoint          = optional(bool)
    master_ipv4_cidr_block           = optional(string)
    cloud_sql_ipv4_cidr_block        = optional(string)
    web_server_ipv4_cidr_block       = optional(string)
    enable_privately_used_public_ips = optional(bool)
  })
  default = null
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "recovery_config" {
  description = "The configuration settings for recovery, for Cloud Composer 2 only."
  type = object({
    scheduled_snapshots_config = object({
      enabled                    = bool
      snapshot_location          = optional(string)
      snapshot_creation_schedule = optional(string)
      time_zone                  = optional(string)
    })
  })
  default = null
}

variable "region" {
  description = "The location or Compute Engine region for the environment."
  type        = string
}

variable "resilience_mode" {
  description = "The resilience mode states whether high resilience is enabled for the environment or not. Values for resilience mode are HIGH_RESILIENCE for high resilience and STANDARD_RESILIENCE for standard resilience. For Cloud Composer 2.1.15 or newer only."
  type        = string
  default     = null
}

variable "software_config" {
  description = "The configuration settings for software inside the environment."
  type = object({
    airflow_config_overrides = optional(map(string))
    pypi_packages            = optional(map(string))
    env_variables            = optional(map(string))
    image_version            = optional(string)
    python_version           = optional(string)
    scheduler_count          = optional(number)
  })
  default = null
}

variable "web_server_config" {
  description = "The configuration settings for the Airflow web server App Engine instance. For Cloud Composer 1 only."
  type = object({
    machine_type = string
  })
  default = null
}

variable "workloads_config" {
  description = "The Kubernetes workloads configuration for GKE cluster associated with the Cloud Composer environment. For Cloud Composer 2 only."
  type = object({
    scheduler = optional(object({
      cpu        = optional(number)
      count      = optional(number)
      memory_gb  = optional(number)
      storage_gb = optional(number)
    }))
    triggerer = optional(object({
      cpu       = optional(number)
      count     = optional(number)
      memory_gb = optional(number)
    }))
    web_server = optional(object({
      cpu        = optional(number)
      storage_gb = optional(number)
      memory_gb  = optional(number)
    }))
    worker = optional(object({
      cpu        = optional(number)
      storage_gb = optional(number)
      memory_gb  = optional(number)
      min_count  = optional(number)
      max_count  = optional(number)
    }))
  })
  default = null

}

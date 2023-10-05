# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Terraform Variables.

variable "composer_config" {
  description = "Cloud Composer config."
  type = object({
    environment_size = optional(string, "ENVIRONMENT_SIZE_SMALL")
    software_config = optional(object({
      airflow_config_overrides       = optional(map(string), {})
      pypi_packages                  = optional(map(string), {})
      env_variables                  = optional(map(string), {})
      image_version                  = optional(string, "composer-2-airflow-2")
      cloud_data_lineage_integration = optional(bool, true)
    }), {})
    web_server_access_control = optional(map(string), {})
    workloads_config = optional(object({
      scheduler = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
        count      = optional(number, 1)
        }
      ), {})
      web_server = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
      }), {})
      worker = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
        min_count  = optional(number, 1)
        max_count  = optional(number, 3)
        }
      ), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "data_catalog_tags" {
  description = "List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format."
  type = map(object({
    description = optional(string)
    iam         = optional(map(list(string)), {})
  }))
  nullable = false
  default = {
    "3_Confidential" = {}
    "2_Private"      = {}
    "1_Sensitive"    = {}
  }
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_services" {
  description = "Flag to enable or disable services in the Data Platform."
  type = object({
    composer                = optional(bool, true)
    dataproc_history_server = optional(bool, true)
  })
  default = {}
}

variable "groups" {
  description = "User groups."
  type        = map(string)
  default = {
    data-analysts  = "gcp-data-analysts"
    data-engineers = "gcp-data-engineers"
    data-security  = "gcp-data-security"
  }
}

variable "location" {
  description = "Location used for multi-regional resources."
  type        = string
  default     = "eu"
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects."
  type = object({
    host_project      = optional(string)
    network_self_link = optional(string)
    subnet_self_link  = optional(string)
    composer_ip_ranges = optional(object({
      connection_subnetwork = optional(string)
      cloud_sql             = optional(string, "10.20.10.0/24")
      gke_master            = optional(string, "10.20.11.0/28")
      pods_range_name       = optional(string, "pods")
      services_range_name   = optional(string, "services")
    }), {})
  })
  nullable = false
  default  = {}
  validation {
    condition     = (var.network_config.composer_ip_ranges.cloud_sql == null) != (var.network_config.composer_ip_ranges.connection_subnetwork == null)
    error_message = "One, and only one, of `network_config.composer_ip_ranges.cloud_sql` or `network_config.composer_ip_ranges.connection_subnetwork` must be specified."
  }
}

variable "organization_domain" {
  description = "Organization domain."
  type        = string
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_config" {
  description = "Provide 'billing_account_id' value if project creation is needed, uses existing 'project_ids' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = optional(string, null)
    parent             = string
    project_ids = optional(object({
      landing    = string
      processing = string
      curated    = string
      common     = string
      }), {
      landing    = "lnd"
      processing = "prc"
      curated    = "cur"
      common     = "cmn"
      }
    )
  })
  validation {
    condition     = var.project_config.billing_account_id != null || var.project_config.project_ids != null
    error_message = "At least one of project_config.billing_account_id or var.project_config.project_ids should be set."
  }
}

variable "project_suffix" {
  description = "Suffix used only for project ids."
  type        = string
  default     = null
}

variable "region" {
  description = "Region used for regional resources."
  type        = string
  default     = "europe-west1"
}

variable "service_encryption_keys" {
  description = "Cloud KMS to use to encrypt different services. Key location should match service region."
  type = object({
    bq       = optional(string)
    composer = optional(string)
    compute  = optional(string)
    storage  = optional(string)
  })
  nullable = false
  default  = {}
}

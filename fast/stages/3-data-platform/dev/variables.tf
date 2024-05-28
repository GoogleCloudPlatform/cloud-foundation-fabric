# Copyright 2024 Google LLC
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
    disable_deployment = optional(bool)
    environment_size   = optional(string, "ENVIRONMENT_SIZE_SMALL")
    software_config = optional(
      object({
        airflow_config_overrides       = optional(any)
        pypi_packages                  = optional(any)
        env_variables                  = optional(map(string))
        image_version                  = string
        cloud_data_lineage_integration = optional(bool, true)
      }),
      { image_version = "composer-2-airflow-2" }
    )
    workloads_config = optional(
      object({
        scheduler = optional(
          object({
            cpu        = number
            memory_gb  = number
            storage_gb = number
            count      = number
          }),
          {
            cpu        = 0.5
            memory_gb  = 1.875
            storage_gb = 1
            count      = 1
          }
        )
        web_server = optional(
          object({
            cpu        = number
            memory_gb  = number
            storage_gb = number
          }),
          {
            cpu        = 0.5
            memory_gb  = 1.875
            storage_gb = 1
          }
        )
        worker = optional(
          object({
            cpu        = number
            memory_gb  = number
            storage_gb = number
            min_count  = number
            max_count  = number
          }),
          {
            cpu        = 0.5
            memory_gb  = 1.875
            storage_gb = 1
            min_count  = 1
            max_count  = 3
          }
        )
    }))
  })
  default = {
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    software_config = {
      image_version = "composer-2-airflow-2"
    }
    workloads_config = {
      scheduler = {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server = {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker = {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }
  }
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
  default     = true
  nullable    = false
}

variable "groups_dp" {
  description = "Data Platform groups."
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

variable "network_config_composer" {
  description = "Network configurations to use for Composer."
  type = object({
    cloudsql_range    = string
    gke_master_range  = string
    gke_pods_name     = string
    gke_services_name = string
  })
  default = {
    cloudsql_range    = "192.168.254.0/24"
    gke_master_range  = "192.168.255.0/28"
    gke_pods_name     = "pods"
    gke_services_name = "services"
  }
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "project_config" {
  description = "Provide projects configuration."
  type = object({
    project_create = optional(bool, true)
    project_ids = optional(object({
      drop     = string
      load     = string
      orc      = string
      trf      = string
      dwh-lnd  = string
      dwh-cur  = string
      dwh-conf = string
      common   = string
      exp      = string
      })
    )
  })
  default = {}
}

variable "project_services" {
  description = "List of core services enabled on all projects."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com"
  ]
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
    bq       = string
    composer = string
    dataflow = string
    storage  = string
    pubsub   = string
  })
  default = null
}

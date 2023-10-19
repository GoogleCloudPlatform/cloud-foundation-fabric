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

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}

variable "composer_config" {
  description = "Cloud Composer configuration options."
  type = object({
    disable_deployment = optional(bool)
    environment_size   = string
    software_config = object({
      airflow_config_overrides       = optional(any)
      pypi_packages                  = optional(any)
      env_variables                  = optional(map(string))
      image_version                  = string
      cloud_data_lineage_integration = optional(bool, true)
    })
    workloads_config = object({
      scheduler = object(
        {
          cpu        = number
          memory_gb  = number
          storage_gb = number
          count      = number
        }
      )
      web_server = object(
        {
          cpu        = number
          memory_gb  = number
          storage_gb = number
        }
      )
      worker = object(
        {
          cpu        = number
          memory_gb  = number
          storage_gb = number
          min_count  = number
          max_count  = number
        }
      )
    })
  })
  default = {
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    software_config = {
      image_version                  = "composer-2-airflow-2"
      cloud_data_lineage_integration = true
    }
    workloads_config = null
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

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folder to be used for the networking resources in folders/nnnn format."
  type = object({
    data-platform-dev = string
  })
}

variable "groups-dp" {
  description = "Data Platform groups."
  type        = map(string)
  default = {
    data-analysts  = "gcp-data-analysts"
    data-engineers = "gcp-data-engineers"
    data-security  = "gcp-data-security"
  }
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC project ids."
  type = object({
    dev-spoke-0 = string
  })
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

variable "organization" {
  # tfdoc:variable:source 00-globals
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 00-globals
  description = "Unique prefix used for resource names. Not used for projects if 'project_create' is null."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 13
    error_message = "Use a maximum of 12 characters for prefix."
  }
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

variable "subnet_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC subnet self links."
  type = object({
    dev-spoke-0 = map(string)
  })
  default = null
}

variable "vpc_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC self links."
  type = object({
    dev-spoke-0 = string
  })
  default = null
}

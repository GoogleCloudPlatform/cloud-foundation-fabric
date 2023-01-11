# Copyright 2022 Google LLC
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
  # tfdoc:variable:source 00-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "billing_account" {
  # tfdoc:variable:source 00-globals
  description = "Billing account id and organization id ('nnnnnnnn' or null)."
  type = object({
    id              = string
    organization_id = number
  })
}

variable "composer_config" {
  description = "Cloud Composer configuration options."
  type = object({
    node_count      = number
    airflow_version = string
    env_variables   = map(string)
  })
  default = {
    node_count      = 3
    airflow_version = "composer-1.17.5-airflow-2.1.4"
    env_variables   = {}
  }
}

variable "data_catalog_tags" {
  description = "List of Data Catalog Policy tags to be created with optional IAM binging configuration in {tag => {ROLE => [MEMBERS]}} format."
  type        = map(map(list(string)))
  nullable    = false
  default = {
    "3_Confidential" = null
    "2_Private"      = null
    "1_Sensitive"    = null
  }
}

variable "data_force_destroy" {
  description = "Flag to set 'force_destroy' on data services like BigQery or Cloud Storage."
  type        = bool
  default     = false
}

variable "folder_ids" {
  # tfdoc:variable:source 01-resman
  description = "Folder to be used for the networking resources in folders/nnnn format."
  type = object({
    data-platform-dev = string
  })
}

variable "groups" {
  description = "Groups."
  type        = map(string)
  default = {
    data-analysts  = "gcp-data-analysts"
    data-engineers = "gcp-data-engineers"
    data-security  = "gcp-data-security"
  }
}

variable "host_project_ids" {
  # tfdoc:variable:source 02-networking
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
    web_server_range  = string
  })
  default = {
    cloudsql_range    = "192.168.254.0/24"
    gke_master_range  = "192.168.255.0/28"
    gke_pods_name     = "pods"
    gke_services_name = "services"
    web_server_range  = "192.168.255.16/28"
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
  # tfdoc:variable:source 02-networking
  description = "Shared VPC subnet self links."
  type = object({
    dev-spoke-0 = map(string)
  })
  default = null
}

variable "vpc_self_links" {
  # tfdoc:variable:source 02-networking
  description = "Shared VPC self links."
  type = object({
    dev-spoke-0 = string
  })
  default = null
}

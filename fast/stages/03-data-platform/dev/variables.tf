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

variable "billing_account_id" {
  # tfdoc:variable:source 00-bootstrap
  description = "Billing account id."
  type        = string
}

variable "composer_config" {
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

variable "data_force_destroy" {
  description = "Flag to set 'force_destroy' on data services like BiguQery or Cloud Storage."
  type        = bool
  default     = false
}

variable "folder_id" {
  # tfdoc:variable:source resman
  description = "Folder to be used for the networking resources in folders/nnnn format."
  type        = string
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

variable "network_config" {
  description = "Network configurations to use. Specify a shared VPC to use, if null networks will be created in projects."
  type = object({
    host_project      = string
    network_self_link = string
    subnet_self_links = object({
      load           = string
      transformation = string
      orchestration  = string
    })
  })
}

variable "network_config_composer" {
  description = "Network configurations to use for Composer."
  type = object({
    composer_ip_ranges = object({
      cloudsql   = string
      gke_master = string
      web_server = string
    })
    composer_secondary_ranges = object({
      pods     = string
      services = string
    })
  })
  default = {
    composer_ip_ranges = {
      cloudsql   = "172.18.29.0/24"
      gke_master = "172.18.30.0/28"
      web_server = "172.18.30.16/28"
    }
    composer_secondary_ranges = {
      pods     = "pods"
      services = "services"
    }
  }
}

variable "organization_domain" {
  description = "Organization domain."
  type        = string
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 00-bootstrap
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

variable "service_encryption_keys" { # service encription key
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

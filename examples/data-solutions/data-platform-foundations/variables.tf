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
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type = object({
    network_self_link = string
    subnet_self_links = object({
      load           = string
      transformation = string
      orchestration  = string
    })
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
    network_self_link         = null
    subnet_self_links         = null
    composer_ip_ranges        = null
    composer_secondary_ranges = null
  }
}

variable "organization" {
  description = "Organization details."
  type = object({
    domain = string
  })
}

variable "prefix" {
  description = "Unique prefix used for resource names. Not used for projects if 'project_create' is null."
  type        = string
}

variable "project_create" {
  description = "Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  description = "Project id, references existing project if `project_create` is null."
  type = object({
    landing             = string
    load                = string
    orchestration       = string
    trasformation       = string
    datalake-l0         = string
    datalake-l1         = string
    datalake-l2         = string
    datalake-playground = string
    common              = string
    exposure            = string
  })
  default = {
    landing             = "lnd"
    load                = "lod"
    orchestration       = "orc"
    trasformation       = "trf"
    datalake-l0         = "dtl-0"
    datalake-l1         = "dtl-1"
    datalake-l2         = "dtl-2"
    datalake-playground = "dtl-plg"
    common              = "cmn"
    exposure            = "exp"
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

variable "location_config" {
  description = "Locations where resources will be deployed. Map to configure region and multiregion specs."
  type = object({
    region       = string
    multi_region = string
  })
  default = {
    region       = "europe-west1"
    multi_region = "eu"
  }
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

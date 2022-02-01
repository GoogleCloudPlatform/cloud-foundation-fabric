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

# tfdoc:file:description Terraform Variables

variable "composer_config" {
  type = object({
    ip_range_cloudsql   = string
    ip_range_gke_master = string
    ip_range_web_server = string
    region              = string
    secondary_ip_range = object({
      pods     = string
      services = string
    })
  })
  default = {
    ip_range_cloudsql   = "10.20.10.0/24"
    ip_range_gke_master = "10.20.11.0/28"
    ip_range_web_server = "10.20.11.16/28"
    region              = "europe-west1"
    secondary_ip_range = {
      pods     = "10.10.8.0/22"
      services = "10.10.12.0/24"
    }
  }
}

variable "data_force_destroy" {
  description = "Flag to set 'force_destroy' on data services like biguqery or cloud storage."
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
  description = "Shared VPC to use. If not null networks will be created in projects."
  type = object({
    network = string
    vpc_subnet_range = object({
      load           = string
      transformation = string
      orchestration  = string
    })
  })
  default = {
    network = null
    vpc_subnet_range = {
      load           = "10.10.0.0/24"
      transformation = "10.10.0.0/24"
      orchestration  = "10.10.0.0/24"
    }
  }
}

variable "organization" {
  description = "Organization details."
  type = object({
    domain = string
  })
}

variable "prefix" {
  description = "Unique prefix used for resource names. Not used for project if 'project_create' is null."
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
    landing       = string
    load          = string
    orchestration = string
    trasformation = string
    datalake      = string
    security      = string
  })
  default = {
    landing       = "lnd"
    load          = "lod"
    orchestration = "orc"
    trasformation = "trf"
    datalake      = "dtl"
    security      = "sec"
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

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
    environment     = map(string)
  })
  default = {
    node_count      = 3
    airflow_version = "TODO"
    environment     = {}
  }
}
variable "composer_config" {
  type = object({
    node_count = number
    #TODO Move to network
    ip_range_cloudsql   = string
    ip_range_gke_master = string
    ip_range_web_server = string
    #TODO hardcoded
    project_policy_boolean = map(bool)
    region                 = string
    ip_allocation_policy = object({
      use_ip_aliases                = string
      cluster_secondary_range_name  = string
      services_secondary_range_name = string
    })
    #TODO Add Env variables, Airflow version
  })
  default = {
    node_count             = 3
    ip_range_cloudsql      = "10.20.10.0/24"
    ip_range_gke_master    = "10.20.11.0/28"
    ip_range_web_server    = "10.20.11.16/28"
    project_policy_boolean = null
    region                 = "europe-west1"
    ip_allocation_policy = {
      use_ip_aliases                = "true"
      cluster_secondary_range_name  = "pods"
      services_secondary_range_name = "services"
    }
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
  description = "Network configurations to use. Specify a shared VPC to use, if null networks will be created in projects."
  type = object({
    #TODO hardcoded Cloud NAT
    network_self_link = string
    #TODO hardcoded VPC ranges
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
    enable_cloud_nat = false
    host_project     = null
    network          = null

    vpc_subnet = {
      load = {
        range           = "10.10.0.0/24"
        secondary_range = null
      }
      transformation = {
        range           = "10.10.0.0/24"
        secondary_range = null
      }
      orchestration = {
        range = "10.10.0.0/24"
        secondary_range = {
          pods     = "10.10.8.0/22"
          services = "10.10.12.0/24"
        }
      }
    }
    vpc_subnet_self_link = null
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

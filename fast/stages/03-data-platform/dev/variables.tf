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
    node_count             = number
    ip_range_cloudsql      = string
    ip_range_gke_master    = string
    ip_range_web_server    = string
    project_policy_boolean = map(bool)
    region                 = string
    ip_allocation_policy = object({
      use_ip_aliases                = string
      cluster_secondary_range_name  = string
      services_secondary_range_name = string
    })
  })
  default = {
    node_count          = 3
    ip_range_cloudsql   = "172.18.29.0/24"
    ip_range_gke_master = "172.18.30.0/28"
    ip_range_web_server = "172.18.30.16/28"
    project_policy_boolean = {
      "constraints/compute.requireOsLogin" = true
    }
    region = "europe-west1"
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

variable "enable_cloud_nat" {
  description = "Network Cloud NAT flag."
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

variable "network_config" {
  description = "Network configurations to use. Specify a shared VPC to use, if null networks will be created in projects."
  type = object({
    host_project = string
    network      = string
    vpc_subnet_self_link = object({
      load           = string
      transformation = string
      orchestration  = string
    })
  })
}

variable "organization" {
  # tfdoc:variable:source 00-bootstrap
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
  # tfdoc:variable:source 00-bootstrap
  description = "Unique prefix used for resource names. Not used for projects if 'project_create' is null."
  type        = string
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

variable "service_encryption_keys" { # service encription key
  description = "Cloud KMS to use to encrypt different services. Key location should match service region."
  type = object({
    bq       = string
    composer = string
    dataflow = string
    storage  = string
    pubsub   = string
  })
<<<<<<< HEAD
  default = {
    bq       = null
    composer = null
    dataflow = null
    storage  = null
    #TODO remove test
    pubsub = "projects/fs01-dev-sec-core-0/locations/global/keyRings/dev-global/cryptoKeys/dp_pubsub"
  }
=======
  default = null
>>>>>>> b976dd6 (First commit)
}

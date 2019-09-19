# Copyright 2019 Google LLC
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

variable "billing_account_id" {
  description = "Billing account id used as default for new projects."
  type        = string
}

variable "host_owners" {
  description = "Host project owners, in IAM format."
  default     = []
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "root_node" {
  description = "Hierarchy node where projects will be created, 'organizations/org_id' or 'folders/folder_id'."
  type        = string
}

variable "subnets" {
  description = "Shared VPC subnet definitions."
  default = [
    {
      subnet_name           = "networking"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = "europe-west1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "data"
      subnet_ip             = "10.0.16.0/24"
      subnet_region         = "europe-west1"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "gke"
      subnet_ip             = "10.0.32.0/24"
      subnet_region         = "europe-west1"
      subnet_private_access = "true"
    },
  ]
}

variable "subnet_secondary_ranges" {
  description = "Shared VPC subnets secondary range definitions."
  default = {
    networking = [],
    data       = [],
    gke = [
      {
        range_name    = "services"
        ip_cidr_range = "172.16.0.0/24"
      },
      {
        range_name    = "pods"
        ip_cidr_range = "10.128.0.0/18"
      }
    ]
  }
}

variable "project_services" {
  description = "Service APIs enabled by default in new projects."
  default = [
    "bigquery-json.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "deploymentmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
  ]
}

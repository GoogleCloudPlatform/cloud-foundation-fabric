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

variable "kms_keyring_location" {
  description = "Location used for the KMS keyring."
  default     = "europe"
}

variable "kms_keyring_name" {
  description = "Name used for the KMS keyring."
  default     = "svpc-example"
}

variable "oslogin_admins_gce" {
  description = "GCE project oslogin admin members, in IAM format."
  default     = []
}

variable "oslogin_users_gce" {
  description = "GCE project oslogin user members, in IAM format."
  default     = []
}

variable "owners_gce" {
  description = "GCE project owners, in IAM format."
  default     = []
}

variable "owners_gke" {
  description = "GKE project owners, in IAM format."
  default     = []
}

variable "owners_host" {
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
      subnet_name           = "gce"
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
    gce        = [],
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
    "resourceviews.googleapis.com",
    "stackdriver.googleapis.com",
  ]
}

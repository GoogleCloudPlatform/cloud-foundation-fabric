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

variable "cmek_encryption" {
  description = "Flag to enable CMEK on GCP resources created."
  type        = bool
  default     = false
}

variable "data_eng_principals" {
  description = "Groups with admin/developer role on enabled services and Service Account Token creator role on service accounts in IAM format, eg 'group:group@domain.com'."
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = true
  nullable    = false
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type = object({
    host_project     = optional(string)
    subnet_self_link = optional(string)
  })
  nullable = false
  default  = {}
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_config" {
  description = "Provide 'billing_account_id' value if project creation is needed, uses existing 'project_id' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. If project is created, `var.prefix` will be used."
  type = object({
    billing_account_id = optional(string),
    parent             = string,
    project_id         = optional(string, "gcs-df-bq")
  })
  nullable = false
  validation {
    condition     = var.project_config.billing_account_id != null || var.project_config.project_id != null
    error_message = "At least one of project_config.billing_account_id or var.project_config.project_id should be set."
  }
}

variable "region" {
  description = "The region where resources will be deployed."
  type        = string
  default     = "europe-west1"
}

variable "vpc_subnet_range" {
  description = "Ip range used for the VPC subnet created for the example."
  type        = string
  default     = "10.0.0.0/20"
}

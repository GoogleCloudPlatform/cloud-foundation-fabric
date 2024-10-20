/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


variable "bucket_name" {
  description = "GCS bucket name to store the Vertex AI artifacts."
  type        = string
  default     = null
}

variable "dataset_name" {
  description = "BigQuery Dataset to store the training data."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Prevent Terraform from destroying data storage resources (storage buckets, GKE clusters, CloudSQL instances) in this blueprint. When this field is set in Terraform state, a terraform destroy or terraform apply that would delete data storage resources will fail."
  type        = bool
  default     = false
  nullable    = false
}

variable "groups" {
  description = "Name of the groups (name@domain.org) to apply opinionated IAM permissions."
  type = object({
    gcp-ml-ds     = optional(string)
    gcp-ml-eng    = optional(string)
    gcp-ml-viewer = optional(string)
  })
  default  = {}
  nullable = false
}

variable "identity_pool_assertions" {
  description = "Assertions to be used by Workload Identityf Federation on tokens, for example: assertion.repository_owner=='ORGANIZATION'."
  type        = string
  default     = null
}

variable "identity_pool_claims" {
  description = "Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). If a not null value is provided, then google_iam_workload_identity_pool resource will be created."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to be assigned at project level."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Location used for multi-regional resources."
  type        = string
  default     = "eu"
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type = object({
    host_project      = string
    network_self_link = string
    subnet_self_link  = string
  })
  default = null
}

variable "notebooks" {
  description = "Vertex AI workbenches to be deployed. Service Account runtime/instances deployed."
  type = map(object({
    type             = string
    machine_type     = optional(string, "n1-standard-4")
    internal_ip_only = optional(bool, true)
    idle_shutdown    = optional(bool, false)
    owner            = optional(string)
  }))
  validation {
    condition = alltrue([
    for k, v in var.notebooks : contains(["USER_MANAGED", "MANAGED"], v.type)])
    error_message = "All `type` must be one of `USER_MANAGED` or `MANAGED`."
  }
  validation {
    condition = alltrue([
    for k, v in var.notebooks : (v.type == "MANAGED" && try(v.owner != null, false) || v.type == "USER_MANAGED")])
    error_message = "`owner` must be set for `MANAGED` instances."
  }
}

variable "prefix" {
  description = "Prefix used for the project id."
  type        = string
  default     = null
}

variable "project_config" {
  description = "Provide 'billing_account_id' value if project creation is needed, uses existing 'project_id' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = optional(string)
    parent             = optional(string)
    project_id         = string
  })
  validation {
    condition     = var.project_config.project_id != null
    error_message = "Project id must be set."
  }
  nullable = false
}

variable "region" {
  description = "Region used for regional resources."
  type        = string
  default     = "europe-west4"
}

variable "repo_name" {
  description = "Cloud Source Repository name. null to avoid to create it."
  type        = string
  default     = null
}

variable "service_encryption_keys" {
  description = "Cloud KMS to use to encrypt different services. Key location should match service region."
  type = object({
    aiplatform    = optional(string)
    bq            = optional(string)
    notebooks     = optional(string)
    secretmanager = optional(string)
    storage       = optional(string)
  })
  default  = {}
  nullable = false
}

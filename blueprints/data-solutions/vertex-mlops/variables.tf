/**
 * Copyright 2022 Google LLC
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

variable "groups" {
  description = "Name of the groups (name@domain.org) to apply opinionated IAM permissions."
  type = object({
    gcp-ml-ds     = string
    gcp-ml-eng    = string
    gcp-ml-viewer = string
  })
  default = {
    gcp-ml-ds     = null
    gcp-ml-eng    = null
    gcp-ml-viewer = null
  }
  nullable = false
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
  description = "Vertex AI workbenchs to be deployed."
  type = map(object({
    owner            = string
    region           = string
    subnet           = string
    internal_ip_only = optional(bool, false)
    idle_shutdown    = optional(bool)
  }))
  default  = {}
  nullable = false
}

variable "prefix" {
  description = "Prefix used for the project id."
  type        = string
  default     = null
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
  type        = string
}

variable "project_services" {
  description = "List of core services enabled on all projects."
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com"
  ]
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

variable "sa_mlops_name" {
  description = "Name for the MLOPs Service Account."
  type        = string
  default     = "sa-mlops"
}

variable "service_encryption_keys" { # service encription key
  description = "Cloud KMS to use to encrypt different services. Key location should match service region."
  type = object({
    bq      = string
    compute = string
    storage = string
  })
  default = null
}
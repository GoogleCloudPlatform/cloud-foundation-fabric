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


variable "group_iam" {
  description = "Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "identity_pool_claims" {
  description = "Claims to be used by Workload Identity Federation (i.e.: attribute.repository/ORGANIZATION/REPO). If a not null value is provided, then google_iam_workload_identity_pool resource will be created."
  type        = string
  default     = null
}

variable "kms_service_agents" {
  description = "KMS IAM configuration in as service => [key]."
  type        = map(list(string))
  default     = {}
}

variable "labels" {
  description = "Labels to be assigned at project level."
  type        = map(string)
  default     = {}
}


variable "notebooks" {
  description = "Vertex AI workbenchs to be deployed."
  type = map(object({
    owner                 = string
    region                = string
    subnet                = string
    internal_ip_only      = bool
    idle_shutdown_timeout = bool
  }))
  default = null
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

variable "vpc" {
  description = "Shared VPC configuration for the project."
  type = object({
    host_project = string
    gke_setup = object({
      enable_security_admin     = bool
      enable_host_service_agent = bool
    })
    subnets_iam = map(list(string))
  })
  default = null
}

variable "vpc_local" {
  description = "Local VPC configuration for the project."
  type = object({
    name              = string
    psa_config_ranges = map(string)
    subnets = list(object({
      name               = string
      region             = string
      ip_cidr_range      = string
      secondary_ip_range = map(string)
      }
    ))
    }
  )
  default = {
    "name" : "default",
    "subnets" : [
      {
        "name" : "default",
        "region" : "europe-west1",
        "ip_cidr_range" : "10.1.0.0/24",
        "secondary_ip_range" : null
      },
      {
        "name" : "default",
        "region" : "europe-west4",
        "ip_cidr_range" : "10.4.0.0/24",
        "secondary_ip_range" : null
      }
    ],
    "psa_config_ranges" : {
      "vertex" : "10.13.0.0/18"
    }
  }
}



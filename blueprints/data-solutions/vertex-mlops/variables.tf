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


variable "billing_account_id" {
  description = "Billing account id."
  type        = string
}

variable "bucket_name" {
  description = "Create GCS Bucket."
  type        = string
  default     = null
}

variable "dataset_name" {
  description = "Create BigQuery Datasets."
  type        = string
  default     = null
}

variable "env" {
  description = "Environment (dev,stg,prd)"
  type        = string
  default     = "dev"
}

variable "folder_id" {
  description = "Folder ID for the folder where the project will be created."
  type        = string
}

variable "groups" {
  description = "User groups."
  type        = map(string)
  default = {
    data-scientists = "gcp-ml-ds"
    ml-engineers    = "gcp-ml-eng"
  }
}

variable "identity_pool_claims" {
  description = "Claims to be used by Workload Identity Federation. i.e.: attribute.repository/ORGANIZATION/REPO"
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

variable "org_policies" {
  description = "Org-policy overrides at project level."
  type = map(object({
    inherit_from_parent = optional(bool) # for list policies only.
    reset               = optional(bool)

    # default (unconditional) values
    allow = optional(object({
      all    = optional(bool)
      values = optional(list(string))
    }))
    deny = optional(object({
      all    = optional(bool)
      values = optional(list(string))
    }))
    enforce = optional(bool, true) # for boolean policies only.

    # conditional values
    rules = optional(list(object({
      allow = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      deny = optional(object({
        all    = optional(bool)
        values = optional(list(string))
      }))
      enforce = optional(bool, true) # for boolean policies only.
      condition = object({
        description = optional(string)
        expression  = optional(string)
        location    = optional(string)
        title       = optional(string)
      })
    })), [])
  }))
  default  = {}
  nullable = false
}

variable "organization_domain" {
  description = "Organization domain."
  type        = string
}

variable "prefix" {
  description = "Prefix used for the project id."
  type        = string
  default     = null
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "Project id."
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



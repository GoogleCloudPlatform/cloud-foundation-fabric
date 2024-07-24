/**
 * Copyright 2024 Google LLC
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

variable "composer_config" {
  description = "Composer environment configuration. It accepts only following attributes: `environment_size`, `software_config` and `workloads_config`. See [attribute reference](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/composer_environment#argument-reference---cloud-composer-2) for details on settings variables."
  type = object({
    environment_size = optional(string)
    software_config  = optional(any)
    workloads_config = optional(object({
      scheduler = optional(object({
        count      = optional(number, 1)
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 2)
        storage_gb = optional(number, 1)
      }), {})
      triggerer = optional(object({
        count     = number
        cpu       = number
        memory_gb = number
      }))
      web_server = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 2)
        storage_gb = optional(number, 1)
      }), {})
      worker = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 2)
        min_count  = optional(number, 1)
        max_count  = optional(number, 3)
        storage_gb = optional(number, 1)
      }), {})
    }))
  })
  default = {
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    software_config = {
      image_version = "composer-2-airflow-2"
    }
  }
}

variable "iam_bindings_additive" {
  description = "Map of Role => principal in IAM format (`group:foo@example.org`) to be added on the project."
  type        = map(list(string))
  nullable    = false
  default     = {}
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null networks will be created in projects with preconfigured values."
  type = object({
    host_project      = string
    network_self_link = string
    subnet_self_link  = string
    composer_ip_ranges = object({
      cloudsql   = string
      gke_master = string
    })
    composer_secondary_ranges = object({
      pods     = string
      services = string
    })
  })
  default = null
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
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

variable "region" {
  description = "Region where instances will be deployed."
  type        = string
}

variable "service_encryption_keys" {
  description = "Cloud KMS keys to use to encrypt resources. Provide a key for each region in use."
  type        = map(string)
  default     = {}
  nullable    = false
}

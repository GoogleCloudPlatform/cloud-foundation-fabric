/**
 * Copyright 2025 Google LLC
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

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "location" {
  description = "The geographic location where the connection should reside."
  type        = string
}

variable "connection_id" {
  description = "The ID of the connection."
  type        = string
}

variable "friendly_name" {
  description = "A descriptive name for the connection."
  type        = string
  default     = null
}

variable "description" {
  description = "A description of the connection."
  type        = string
  default     = null
}

variable "encryption_key" {
  description = "The name of the KMS key used for encryption."
  type        = string
  default     = null
}

variable "connection_config" {
  description = "Connection properties."
  type = object({
    cloud_sql = optional(object({
      instance_id = string
      database    = string
      type        = string
      credential = object({
        username = string
        password = string
      })
    }))
    aws = optional(object({
      access_role = object({
        iam_role_id = string
      })
    }))
    azure = optional(object({
      customer_tenant_id              = string
      federated_application_client_id = optional(string)
    }))
    cloud_spanner = optional(object({
      database        = string
      use_parallelism = optional(bool)
      use_data_boost  = optional(bool)
      max_parallelism = optional(number)
      database_role   = optional(string)
    }))
    cloud_resource = optional(object({
    }))
    spark = optional(object({
      metastore_service_config = optional(object({
        metastore_service = string
      }))
      spark_history_server_config = optional(object({
        dataproc_cluster = string
      }))
    }))
  })
  default = {}
}

variable "iam" {
  description = "IAM bindings for the connection in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  default = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  default = {}
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}
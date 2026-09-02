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

variable "atlas_config" {
  description = "MongoDB Atlas configuration."
  type = object({
    cluster_name     = string
    organization_id  = string
    project_name     = string
    region           = string
    database_version = optional(string)
    instance_size    = optional(string)
    provider = object({
      private_key = string
      public_key  = string
    })
  })
}

variable "database_user" {
  description = "MongoDB Atlas database user configuration."
  type = object({
    auth_database_name  = optional(string, "admin")
    aws_iam_type        = optional(string)
    description         = optional(string)
    labels              = optional(map(string), {})
    ldap_auth_type      = optional(string)
    oidc_auth_type      = optional(string)
    password            = optional(string)
    password_wo         = optional(string)
    password_wo_version = optional(number)
    roles = optional(
      map(object({
        collection_name = optional(string)
        database_name   = string
        role_name       = string
      })),
      {
        read_any_database = {
          database_name = "admin"
          role_name     = "readAnyDatabase"
        }
      }
    )
    scopes = optional(map(object({
      type = string
    })), {})
    username  = string
    x509_type = optional(string)
  })

  validation {
    condition = !(
      var.database_user.password != null &&
      var.database_user.password_wo != null
    )
    error_message = "Only one of password or password_wo can be set."
  }

  validation {
    condition = (
      var.database_user.password_wo == null ||
      var.database_user.password_wo_version != null
    )
    error_message = "password_wo_version must be set when password_wo is set."
  }
}

variable "name" {
  description = "Prefix used for all resource names."
  type        = string
  nullable    = true
  default     = "mongodb"
}

variable "project_id" {
  description = "Project id where the registries will be created."
  type        = string
}

variable "vpc_config" {
  description = "VPC configuration."
  type = object({
    psc_cidr_block = string
    network_name   = string
    subnetwork_id  = string
  })
}

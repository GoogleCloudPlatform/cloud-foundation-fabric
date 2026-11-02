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

variable "database_users" {
  description = "MongoDB Atlas database users configuration. The map key is used as the username."
  type = map(object({
    auth_database_name = optional(string, "admin")
    aws_iam_type       = optional(string)
    description        = optional(string)
    labels             = optional(map(string), {})
    ldap_auth_type     = optional(string)
    oidc_auth_type     = optional(string)
    password = optional(object({
      value      = optional(string)
      path       = optional(string)
      wo_version = optional(number)
    }))
    roles = optional(
      map(object({
        collection_name = optional(string)
        database_name   = string
        role_name       = string
      })),
      {}
    )
    scopes = optional(map(object({
      type = string
    })), {})
    x509_type = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.database_users :
      try(v.password.value, null) == null || try(v.password.path, null) == null
    ])
    error_message = "Only one of password.value and password.path can be set."
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

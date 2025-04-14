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

variable "admin_principals" {
  description = "Users, groups and/or service accounts that are assigned roles, in IAM format (`group:foo@example.com`)."
  type        = list(string)
  default     = []
}

variable "cloudsql_config" {
  description = "Cloud SQL Postgres config."
  type = object({
    name             = optional(string, "gitlab-0")
    database_version = optional(string, "POSTGRES_13")
    tier             = optional(string, "db-custom-2-8192")
  })
  default  = {}
  nullable = false
}

variable "gcs_config" {
  description = "GCS for Object Storage config."
  type = object({
    enable_versioning = optional(bool, false)
    location          = optional(string, "EU")
    storage_class     = optional(string, "STANDARD")
  })
  default  = {}
  nullable = false
}

variable "gitlab_config" {
  description = "Gitlab configuration."
  type = object({
    hostname = optional(string, "gitlab.gcp.example.com")
    mail = optional(object({
      enabled = optional(bool, false)
      sendgrid = optional(object({
        api_key        = optional(string)
        email_from     = optional(string, null)
        email_reply_to = optional(string, null)
      }), null)
    }), {})
    saml = optional(object({
      forced                 = optional(bool, false)
      idp_cert_fingerprint   = string
      sso_target_url         = string
      name_identifier_format = optional(string, "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress")
    }), null)
    ha_required = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "gitlab_instance_config" {
  description = "Gitlab Compute Engine instance config."
  type = object({
    instance_type = optional(string, "n2-highcpu-8")
    name          = optional(string, "gitlab-0")
    network_tags  = optional(list(string), [])
    replica_zone  = optional(string)
    zone          = optional(string)
    boot_disk = optional(object({
      size = optional(number, 20)
      type = optional(string, "pd-standard")
    }), {})
    data_disk = optional(object({
      size         = optional(number, 100)
      type         = optional(string, "pd-ssd")
      replica_zone = optional(string)
    }), {})
  })
}

variable "network_config" {
  description = "Shared VPC network configurations to use for Gitlab Runner VM."
  type = object({
    host_project      = optional(string)
    network_self_link = string
    subnet_self_link  = string
  })
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  nullable    = false
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

variable "redis_config" {
  description = "Redis Config."
  type = object({
    memory_size_gb      = optional(number, 1)
    name                = optional(string, "gitlab-0")
    persistence_mode    = optional(string, "RDB")
    rdb_snapshot_period = optional(string, "TWELVE_HOURS")
    tier                = optional(string, "BASIC")
    version             = optional(string, "REDIS_6_X")
  })
  default  = {}
  nullable = false
}

variable "region" {
  description = "GCP Region."
  type        = string
}

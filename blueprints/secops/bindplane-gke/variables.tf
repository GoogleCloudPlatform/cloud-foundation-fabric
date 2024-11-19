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

variable "bindplane_config" {
  description = "Bindplane config."
  type = object({
    tls_certificate_cer = optional(string, null)
    tls_certificate_key = optional(string, null)
  })
  default = {}
}

variable "bindplane_secrets" {
  description = "Bindplane secrets."
  type = object({
    license         = string
    user            = optional(string, "admin")
    password        = optional(string, null)
    secret_key      = string
    sessions_secret = string
  })
}

variable "cluster_config" {
  description = "GKE cluster configuration."
  type = object({
    cluster_name = optional(string, "bindplane-op")
    master_authorized_ranges = optional(map(string), {
      rfc-1918-10-8 = "10.0.0.0/8"
    })
  })
  default = {}
}

variable "dns_config" {
  description = "DNS config."
  type = object({
    bootstrap_private_zone = optional(bool, false)
    domain                 = optional(string, "example.com")
    hostname               = optional(string, "bindplane")
  })
  default = {}
}

variable "network_config" {
  description = "Shared VPC network configurations to use for GKE cluster."
  type = object({
    host_project                  = optional(string)
    network_self_link             = string
    subnet_self_link              = string
    ip_range_gke_master           = string
    secondary_pod_range_name      = optional(string, "pods")
    secondary_services_range_name = optional(string, "services")
  })
}

variable "postgresql_config" {
  description = "Cloud SQL postgresql config."
  type = object({
    availability_type = optional(string, "REGIONAL")
    database_version  = optional(string, "POSTGRES_13")
    tier              = optional(string, "db-g1-small")
  })
  default = {}
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

variable "region" {
  description = "GCP region."
  type        = string
}

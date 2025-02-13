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

variable "chronicle_forwarder" {
  description = "Chronicle GKE forwarder configuration."
  type = object({
    cluster_name = optional(string, "chronicle-log-ingestion")
    master_authorized_ranges = optional(map(string), {
      rfc-1918-10-8 = "10.0.0.0/8"
    })
  })
  default = {}
}

variable "network_config" {
  description = "Shared VPC network configurations to use for GKE cluster."
  type = object({
    host_project        = optional(string)
    network_self_link   = string
    subnet_self_link    = string
    ip_range_gke_master = string
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

variable "region" {
  description = "GCP region."
  type        = string
}

variable "tenants" {
  description = "Chronicle forwarders tenants config."
  type = map(object({
    chronicle_forwarder_image = optional(string, "cf_production_stable")
    chronicle_region          = string
    tenant_id                 = string
    namespace                 = string
    forwarder_config = object({
      config_file_content = optional(string)
      customer_id         = optional(string)
      collector_id        = optional(string)
      secret_key          = optional(string)
      tls_config = optional(object({
        required = optional(bool, false)
        cert_pub = optional(string)
        cert_key = optional(string)
      }), { required = false })
    })
  }))
  default = {}
}

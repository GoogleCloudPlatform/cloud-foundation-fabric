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

variable "annotations" {
  description = "Workstation cluster annotations."
  type        = map(string)
  default     = {}
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    networks       = optional(map(string), {})
    project_ids    = optional(map(string), {})
    subnetworks    = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    workstation_configs = optional(string, "data/workstation-configs")
  })
  nullable = false
  default  = {}
}

variable "display_name" {
  description = "Display name."
  type        = string
  default     = null
}

variable "domain" {
  description = "Domain."
  type        = string
  default     = null
}

variable "id" {
  description = "Workstation cluster ID."
  type        = string
  nullable    = false
  default     = "ws-cluster-0"
}

variable "labels" {
  description = "Workstation cluster labels."
  type        = map(string)
  default     = {}
}

variable "network_config" {
  description = "VPC and subnet for the cluster."
  nullable    = false
  type = object({
    network              = string
    subnetwork           = string
    psc_endpoint_address = optional(string)
  })
}

variable "private_cluster_config" {
  description = "Private cluster config."
  type = object({
    allowed_projects        = optional(list(string))
    enable_private_endpoint = optional(bool, true)
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "Project id where the cluster will be created."
  type        = string
  nullable    = false
}

variable "service_accounts" {
  description = "Project factory managed service accounts to populate context."
  type = map(object({
    email = string
  }))
  nullable = false
  default  = {}
}

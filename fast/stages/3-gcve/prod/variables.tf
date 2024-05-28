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

variable "groups_gcve" {
  description = "GCVE groups."
  type = object({
    gcp-gcve-admins  = string
    gcp-gcve-viewers = string
  })
  default = {
    gcp-gcve-admins  = "gcp-gcve-admins"
    gcp-gcve-viewers = "gcp-gcve-viewers"
  }
  nullable = false
}

variable "iam" {
  description = "Project-level authoritative IAM bindings for users and service accounts in  {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "labels" {
  description = "Project-level labels."
  type        = map(string)
  default     = {}
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "private_cloud_configs" {
  description = "The VMware private cloud configurations. The key is the unique private cloud name suffix."
  type = map(object({
    cidr = string
    zone = string
    # The key is the unique additional cluster name suffix
    additional_cluster_configs = optional(map(object({
      custom_core_count = optional(number)
      node_count        = optional(number, 3)
      node_type_id      = optional(string, "standard-72")
    })), {})
    management_cluster_config = optional(object({
      custom_core_count = optional(number)
      name              = optional(string, "mgmt-cluster")
      node_count        = optional(number, 3)
      node_type_id      = optional(string, "standard-72")
    }), {})
    description = optional(string, "Managed by Terraform.")
  }))
  nullable = false
}

variable "project_services" {
  description = "Additional project services to enable."
  type        = list(string)
  default     = []
  nullable    = false
}

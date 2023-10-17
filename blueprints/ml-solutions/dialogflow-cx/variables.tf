# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Terraform Variables.

variable "language" {
  description = "Dialgogflow CX agent language."
  type        = string
  default     = "it"
}

variable "network_config" {
  description = "Shared VPC network configurations to use. If null network will be created in project."
  type = object({
    host_project      = optional(string)
    network_self_link = optional(string)
    subnets_self_link = optional(object({
      service   = string
      proxy     = string
      connector = string
    }))
  })
  nullable = false
  default  = {}
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_config" {
  description = "Provide 'billing_account_id' value if project creation is needed, uses existing 'project_id' if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = optional(string)
    parent             = string
    project_id         = optional(string, "df-cx")
  })
  validation {
    condition     = var.project_config.billing_account_id != null || var.project_config.project_id != null
    error_message = "At least one of project_config.billing_account_id or var.project_config.project_id should be set."
  }
}

variable "region" {
  description = "Region used for regional resources."
  type        = string
  default     = "europe-west1"
}

variable "webhook_config" {
  description = "Container image to deploy."
  type = object({
    image    = optional(string)
    url_path = optional(string, "handle_webhook")
  })
  default = {}
}

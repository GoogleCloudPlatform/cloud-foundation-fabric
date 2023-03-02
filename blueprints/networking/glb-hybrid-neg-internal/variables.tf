/**
 * Copyright 2023 Google LLC
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

variable "ilb_create" {
  description = "Whether we should create an ILB L4 in front of the test VMs in the spoke."
  type        = string
  default     = false
}

variable "ip_config" {
  description = "The subnet IP configurations."
  type = object({
    spoke_primary       = optional(string, "192.168.101.0/24")
    spoke_secondary     = optional(string, "192.168.102.0/24")
    trusted_primary     = optional(string, "192.168.11.0/24")
    trusted_secondary   = optional(string, "192.168.22.0/24")
    untrusted_primary   = optional(string, "192.168.1.0/24")
    untrusted_secondary = optional(string, "192.168.2.0/24")
  })
  default = {}
}

variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}

variable "project_names" {
  description = "The project names."
  type = object({
    landing  = string
    spoke_01 = string
  })
  default = {
    landing  = "landing"
    spoke_01 = "spoke-01"
  }
}

variable "projects_create" {
  description = "Parameters for the creation of the new project."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "regions" {
  description = "Region definitions."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "europe-west1"
    secondary = "europe-west4"
  }
}

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

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id = string
  })
}

variable "environments" {
  # tfdoc:variable:source 1-resman
  description = "Long environment names."
  type = object({
    dev = object({
      name = string
    })
  })
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folder name => id mappings."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "host_project_ids" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC host project name => id mappings."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 12
    error_message = "Use a maximum of 9 chars for organizations, and 11 chars for tenants."
  }
}

variable "subnet_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Subnet VPC name => { name => self link }  mappings."
  type        = map(map(string))
  nullable    = false
  default     = {}
}

variable "vpc_self_links" {
  # tfdoc:variable:source 2-networking
  description = "Shared VPC name => self link mappings."
  type        = map(string)
  nullable    = false
  default     = {}
}

/**
 * Copyright 2022 Google LLC
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

variable "allowed_domains" {
  description = "List of domains allowed by the squid proxy."
  type        = list(string)
  default = [
    ".google.com",
    ".github.com",
    ".fastlydns.net",
    ".debian.org"
  ]
}

variable "cidrs" {
  description = "CIDR ranges for subnets."
  type        = map(string)
  default = {
    app   = "10.0.0.0/24"
    proxy = "10.0.2.0/28"
    psc   = "10.0.3.0/28"
  }
}

variable "nat_logging" {
  description = "Enables Cloud NAT logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'."
  type        = string
  default     = "ERRORS_ONLY"
}

variable "prefix" {
  description = "Prefix used for resources that need unique names."
  type        = string
}

variable "project_create" {
  description = "Set to non null if project needs to be created."
  type = object({
    billing_account = string
    parent          = string
  })
  default = null
  validation {
    condition = (
      var.project_create == null
      ? true
      : can(regex("(organizations|folders)/[0-9]+", var.project_create.parent))
    )
    error_message = "Project parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_id" {
  description = "Project id used for all resources."
  type        = string
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "europe-west1"
}

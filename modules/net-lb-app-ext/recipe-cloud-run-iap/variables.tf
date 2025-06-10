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

variable "_testing" {
  description = "Populate this variable to avoid triggering the data source."
  type = object({
    name             = string
    number           = number
    services_enabled = optional(list(string), [])
  })
  default = null
}

variable "accesors" {
  description = "List of identities able to access the service via IAP (e.g. group:mygroup@myorg.com)."
  type        = list(string)
  default     = []
}

variable "impersonators" {
  description = "List of identities able to impersonate the service account for programmatica access."
  type        = list(string)
  default     = []
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "region" {
  description = "Region."
  type        = string
}

variable "support_email" {
  description = "Support email for IAP brand."
  type        = string
}

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

variable "bootstrap_user" {
  description = "Email of the nominal user running this stage for the first time."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    billing_account  = optional(string, "data/billing-account")
    context          = optional(string, "data/context.yaml")
    folders          = optional(string, "data/folders")
    organization     = optional(string, "data/organization")
    project_defaults = optional(string, "data/defaults.yaml")
    projects         = optional(string, "data/projects")
  })
  nullable = false
  default  = {}
}

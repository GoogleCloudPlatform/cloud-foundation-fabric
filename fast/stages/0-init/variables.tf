/**
 * Copyright 2026 Google LLC
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

variable "defaults_factory_config" {
  description = "Defaults factory config."
  type        = string
  nullable    = false
  default     = "datasets/classic/defaults.yaml"
}

variable "default_project_config" {
  description = "Flag indicating whether a temporary project needs be created."
  type = object({
    id     = optional(string)
    create = optional(bool, true)
  })
  default  = {}
  nullable = false
  validation {
    condition     = var.default_project_config.create || var.default_project_config.id != null
    error_message = "When 'create' is false a project id must be provided."
  }
}

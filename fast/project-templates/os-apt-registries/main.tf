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

variable "name" {
  description = "Prefix used for all resource names."
  type        = string
  nullable    = true
  default     = "apt-remote"
}

variable "project_id" {
  description = "Project id where the registries will be created."
  type        = string
  default     = "shared-spoke-0"
}

variable "location" {
  description = "Region where the registries will be created."
  type        = string
  default     = "europe-west8"
}

variable "registry_ paths" {
  description = "Remote artifact registry configurations."
  type        = list(string)
  nullable    = false
  default     = ["DEBIAN debian/dists/bookworm"]
  validation {
    condition = alltrue([
      for v in var.registry_paths : length(split(" ", v)) == 2
    ])
    message = "Invalid registry path: format is [BASE] [path]."
  }
  validation {
    condition = alltrue([
      for v in var.registry_paths :
      contains(["DEBIAN", "UBUNTU"], element(split(" ", v), 0))
    ])
    message = "Invalid registry base: only 'DEBIAN' and 'UBUNTU' are supported."
  }
}

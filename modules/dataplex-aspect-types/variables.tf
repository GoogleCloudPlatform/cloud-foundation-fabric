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

variable "aspect_types" {
  description = "Aspect templates. Merged with those defined via the factory."
  type = map(object({
    description       = optional(string)
    display_name      = optional(string)
    labels            = optional(map(string), {})
    metadata_template = optional(string)
    iam               = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  nullable = false
  default  = {}
}

variable "factories_config" {
  description = "Paths to folders for the optional factories."
  type = object({
    aspect_types = optional(string)
    context = optional(object({
      iam_principals = optional(map(string), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "location" {
  description = "Location for aspect types."
  type        = string
  nullable    = false
  default     = "global"
}

variable "project_id" {
  description = "Project id where resources will be created."
  type        = string
}

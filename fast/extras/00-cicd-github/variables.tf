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

variable "commmit_config" {
  description = "Configure commit metadata."
  type = object({
    author  = optional(string, "FAST loader")
    email   = optional(string, "fast-loader@fast.gcp.tf")
    message = optional(string, "FAST initial loading")
  })
  default  = {}
  nullable = false
}

variable "modules_ref" {
  description = "Optional git ref used in module sources."
  type        = string
  default     = null
}

variable "organization" {
  description = "GitHub organization."
  type        = string
}

variable "repositories" {
  description = "Repositories to create."
  type = map(object({
    create_options = optional(object({
      allow = optional(object({
        auto_merge   = optional(bool)
        merge_commit = optional(bool)
        rebase_merge = optional(bool)
        squash_merge = optional(bool)
      }))
      auto_init   = optional(bool)
      description = optional(string)
      features = optional(object({
        issues   = optional(bool)
        projects = optional(bool)
        wiki     = optional(bool)
      }))
      templates = optional(object({
        gitignore = optional(string, "Terraform")
        license   = optional(string)
        repository = optional(object({
          name  = string
          owner = string
        }))
      }), {})
      visibility = optional(string, "private")
    }))
    has_modules   = optional(bool, false)
    populate_from = optional(string)
  }))
  default  = {}
  nullable = true
  validation {
    condition = alltrue([
      for k, v in var.repositories :
      try(regex("^[a-zA-Z0-9_.]+$", k), null) != null
    ])
    error_message = "Repository names must match '^[a-zA-Z0-9_.]+$'."
  }
}

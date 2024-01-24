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

variable "project_id" {
  description = "Id of the project where resources will be created."
  type        = string
}

variable "repository" {
  description = "Map of repositories to manage, including setting IAM permissions."
  type = map(object({
    name            = string
    branch          = optional(string, "main")
    remote_url      = optional(string)
    secret_name     = optional(string)
    secret_version  = optional(string, "v1")
    token           = optional(string)
    service_account = optional(string)
    region          = optional(string)
    iam             = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
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
}


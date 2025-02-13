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

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format. Mutually exclusive with the access_* variables used for basic roles."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_bindings" {
  description = "Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary."
  type = map(object({
    members = list(string)
    role    = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  default  = {}
  nullable = false
}

variable "iam_bindings_additive" {
  description = "Keyring individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  default  = {}
  nullable = false
}

variable "name" {
  description = "Name of the dataform repository."
  type        = string
}

variable "project_id" {
  description = "Id of the project where resources will be created."
  type        = string
}

variable "region" {
  description = "The repository's region."
  type        = string
}

variable "remote_repository_settings" {
  description = "Remote settings required to attach the repository to a remote repository."
  type = object({
    url            = optional(string)
    branch         = optional(string, "main")
    secret_name    = optional(string)
    secret_version = optional(string, "v1")
    token          = optional(string)
  })
  default = null
}

variable "service_account" {
  description = "Service account used to execute the dataform workflow."
  type        = string
  default     = ""
}

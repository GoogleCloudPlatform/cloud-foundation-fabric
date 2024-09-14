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

variable "ca_pool" {
  description = "CA pool."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings."
  type        = map(list(string))
  default     = {}
}

variable "iam_bindings" {
  description = "IAM bindings."
  type = map(object({
    role    = string
    members = list(string)
  }))
  default = {}
}

variable "iam_bindings_additive" {
  description = "IAM bindings."
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}

variable "instance_id" {
  description = "Instance ID."
  type        = string
}

variable "kms_key" {
  description = "KMS key."
  type        = string
  default     = null
}

variable "labels" {
  description = "Instance labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Location."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

variable "repositories" {
  description = "Repositories."
  type = map(object({
    description = optional(string)
    iam         = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
    iam_bindings_additive = optional(map(object({
      role   = string
      member = string
    })), {})
    initial_config = optional(object({
      default_branch = optional(string)
      gitignores     = optional(string)
      license        = optional(string)
      readme         = optional(string)
    }))
    location = string
  }))
}

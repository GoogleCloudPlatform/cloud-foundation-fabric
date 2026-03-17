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

variable "iam" {
  description = "Authoritative IAM bindings in {ROLE => [MEMBERS]} format."
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
  nullable = false
  default  = {}
}

variable "iam_bindings_additive" {
  description = "Individual additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_by_principals_additive" {
  description = "Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam_bindings_additive` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals_conditional" {
  description = "Authoritative IAM binding in {PRINCIPAL => {roles = [roles], condition = {cond}}} format. Principals need to be statically defined to avoid errors. Condition is required."
  type = map(object({
    roles = list(string)
    condition = object({
      expression  = string
      title       = string
      description = optional(string)
    })
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.iam_by_principals_conditional : v.condition != null
    ])
    error_message = "The `condition` attribute is required. Use `iam_by_principals` for non-conditional bindings."
  }
  validation {
    condition = alltrue([
      for title, conditions in {
        for k, v in var.iam_by_principals_conditional :
        v.condition.title => v.condition...
      } :
      length(distinct(conditions)) == 1
    ])
    error_message = "IAM bindings with the same condition title must have identical expressions and descriptions."
  }
}

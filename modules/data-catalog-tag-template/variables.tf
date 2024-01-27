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

variable "factories_config" {
  description = "Paths to data files and folders that enable factory functionality."
  type = object({
    tag_templates = optional(string)
  })
  nullable = false
  default  = {}
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
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

variable "project_id" {
  description = "Id of the project where Tag Templates will be created."
  type        = string
}

variable "tag_templates" {
  description = "Tag templates definitions in the form {TAG_TEMPLATE_ID => TEMPLATE_DEFINITION}."
  type = map(object({
    display_name = optional(string)
    force_delete = optional(bool, false)
    region       = string
    fields = map(object({
      display_name = optional(string)
      description  = optional(string)
      type = object({
        primitive_type = optional(string)
        enum_type = optional(list(object({
          allowed_values = object({
            display_name = string
          })
        })), null)
      })
      is_required = optional(bool, false)
      order       = optional(number)
    }))
  }))
  default = {}
}

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
    context = optional(object({
      regions = optional(map(string), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "Id of the project where Tag Templates will be created."
  type        = string
}

variable "region" {
  description = "Default region for tag templates."
  type        = string
  default     = null
}

variable "tag_templates" {
  description = "Tag templates definitions in the form {TAG_TEMPLATE_ID => TEMPLATE_DEFINITION}."
  type = map(object({
    display_name = optional(string)
    force_delete = optional(bool, false)
    region       = optional(string)
    fields = map(object({
      display_name = optional(string)
      description  = optional(string)
      is_required  = optional(bool, false)
      order        = optional(number)
      type = object({
        primitive_type   = optional(string)
        enum_type_values = optional(list(string))
      })
    }))
    iam = optional(map(list(string)), {})
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
  default = {}
  validation {
    condition = alltrue(flatten([
      for k, v in var.tag_templates : [
        for kf, vf in v.fields : (
          vf.type.primitive_type == null ||
          vf.type.enum_type_values == null
        )
      ]
    ]))
    error_message = "Field type can be primitive or enum, not both."
  }
  validation {
    condition = alltrue(flatten([
      for k, v in var.tag_templates : [
        for kf, vf in v.fields : vf.type.primitive_type == null || contains(
          ["DOUBLE", "STRING", "BOOL", "TIMESTAMP"],
          coalesce(vf.type.primitive_type, "-")
        )
      ]
    ]))
    error_message = "Primitive field type can only be DOUBLE, STRING, BOOL, or TIMESTAMP."
  }
}

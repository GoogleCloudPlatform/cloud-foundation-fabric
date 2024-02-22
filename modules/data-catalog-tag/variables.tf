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
    tags = optional(string)
  })
  nullable = false
  default  = {}
}

variable "tags" {
  description = "Tags definitions in the form {TAG => TAG_DEFINITION}."
  type = map(object({
    project_id = string
    parent     = string
    column     = optional(string)
    location   = string
    template   = string
    fields = map(object({
      double_value    = optional(number)
      string_value    = optional(string)
      timestamp_value = optional(string)
      enum_value      = optional(string)
    }))
  }))
  default = {}
}

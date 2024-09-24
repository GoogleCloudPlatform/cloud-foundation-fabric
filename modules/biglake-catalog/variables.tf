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

variable "databases" {
  description = "Databases."
  type = map(object({
    type = string
    hive_options = object({
      location_uri = string
      parameters   = optional(map(string), {})
    })
    tables = map(object({
      type = string
      hive_options = object({
        table_type    = string
        location_uri  = string
        input_format  = string
        output_format = string
        parameters    = optional(map(string), {})
      })
    }))
  }))
}

variable "location" {
  description = "Location."
  type        = string
}

variable "name" {
  description = "Name."
  type        = string
}

variable "project_id" {
  description = "Project ID."
  type        = string
}

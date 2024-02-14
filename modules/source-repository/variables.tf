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

variable "name" {
  description = "Repository name."
  type        = string
}

variable "project_id" {
  description = "Project used for resources."
  type        = string
}

variable "triggers" {
  description = "Cloud Build triggers."
  type = map(object({
    filename        = string
    included_files  = list(string)
    service_account = string
    substitutions   = map(string)
    template = object({
      branch_name = string
      project_id  = string
      tag_name    = string
    })
  }))
  default  = {}
  nullable = false
}

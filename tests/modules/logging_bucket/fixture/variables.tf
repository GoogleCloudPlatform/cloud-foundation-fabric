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

variable "parent" {
  type = string
}

variable "parent_type" {
  type = string
  validation {
    condition     = contains(["project", "folder", "organization", "billing_account"], var.parent_type)
    error_message = "Parent type must be project, folder, organization or billing_account."
  }
}

variable "location" {
  type    = string
  default = "global"
}

variable "id" {
  type    = string
  default = "mybucket"
}

variable "retention" {
  type    = number
  default = 30
}

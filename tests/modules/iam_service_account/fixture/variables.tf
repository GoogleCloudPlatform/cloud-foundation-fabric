/**
 * Copyright 2021 Google LLC
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

variable "generate_key" {
  type    = bool
  default = false
}

variable "iam" {
  type    = map(list(string))
  default = {}
}

variable "iam_billing_roles" {
  type    = map(list(string))
  default = {}
}

variable "iam_folder_roles" {
  type    = map(list(string))
  default = {}
}

variable "iam_organization_roles" {
  type    = map(list(string))
  default = {}
}

variable "iam_project_roles" {
  type    = map(list(string))
  default = {}
}

variable "iam_storage_roles" {
  type    = map(list(string))
  default = {}
}

variable "prefix" {
  type    = string
  default = null
}

variable "project_id" {
  type    = string
  default = "my-project"
}

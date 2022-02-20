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

variable "api_id" {
  type    = string
  default = "my-api"
}

variable "iam" {
  type    = map(list(string))
  default = null
}

variable "labels" {
  type    = map(string)
  default = null
}

variable "project_id" {
  type    = string
  default = "my-project"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "service_account_create" {
  type    = bool
  default = true
}

variable "service_account_email" {
  type    = string
  default = null
}

variable "spec" {
  type    = string
  default = "Spec contents"
}

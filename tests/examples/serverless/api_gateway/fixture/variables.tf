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

variable "project_create" {
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = {
    billing_account_id = "123456789"
    parent             = "organizations/123456789"
  }
}

variable "project_id" {
  type    = string
  default = "project-1"
}

variable "regions" {
  type = list(string)
  default = [
    "europe-west1",
    "europe-west2"
  ]
}

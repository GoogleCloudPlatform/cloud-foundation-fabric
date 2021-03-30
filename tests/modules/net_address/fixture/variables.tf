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

variable "external_addresses" {
  type    = map(string)
  default = {}
}

variable "global_addresses" {
  type    = list(string)
  default = []
}

variable "internal_addresses" {
  type = map(object({
    region     = string
    subnetwork = string
  }))
  default = {}
}

variable "internal_addresses_config" {
  type = map(object({
    address = string
    purpose = string
    tier    = string
  }))
  default = {}
}

variable "project_id" {
  type    = string
  default = "my-project"
}

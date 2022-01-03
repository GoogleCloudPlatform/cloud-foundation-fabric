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

variable "cloud_config" {
  type    = string
  default = null
}

variable "config_variables" {
  type    = map(any)
  default = {}
}

variable "coredns_config" {
  type    = string
  default = null
}

variable "file_defaults" {
  type = object({
    owner       = string
    permissions = string
  })
  default = {
    owner       = "root"
    permissions = "0644"
  }
}

variable "files" {
  type = map(object({
    content     = string
    owner       = string
    permissions = string
  }))
  default = {}
}

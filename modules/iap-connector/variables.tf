/**
 * Copyright 2020 Google LLC
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

variable "address_name" {
  type    = string
  default = null
}

variable "cert_domains" {
  type    = list(string)
  default = null
}

variable "cert_name" {
  type    = string
  default = null
}

variable "iap_client_id" {
  type = string
}

variable "iap_client_secret" {
  type = string
}


variable "mappings" {
  type = list(object({
    name        = string
    source      = string
    destination = string
  }))
  default = []
}



variable "name" {
  type = string
}

variable "web_user_principals" {
  type    = list(string)
  default = null
}

variable "project_id" {
  type = string
}

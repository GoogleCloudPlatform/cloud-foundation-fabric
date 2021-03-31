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

variable "confidential_compute" {
  type    = bool
  default = false
}

variable "group" {
  type    = any
  default = null
}

variable "iam" {
  type    = map(set(string))
  default = {}
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "metadata" {
  type    = map(string)
  default = {}
}

variable "metadata_list" {
  type    = list(map(string))
  default = []
}

variable "network_interfaces" {
  type = list(object({
    nat        = bool
    network    = string
    subnetwork = string
    addresses = object({
      internal = list(string)
      external = list(string)
    })
    alias_ips = map(list(string))
  }))
  default = [{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
    nat        = false,
    addresses  = null
    alias_ips  = null
  }]
}

variable "service_account_create" {
  type    = bool
  default = false
}

variable "single_name" {
  type    = bool
  default = false
}

variable "use_instance_template" {
  type    = bool
  default = false
}

variable "zones" {
  type    = list(string)
  default = []
}

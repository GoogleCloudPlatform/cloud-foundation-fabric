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

variable "attached_disks" {
  description = "Additional disks, if options is null defaults will be used in its place. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null."
  type        = any
  default     = []
}

variable "attached_disk_defaults" {
  description = "Defaults for attached disks options."
  type        = any
  default = {
    auto_delete  = true
    mode         = "READ_WRITE"
    replica_zone = null
    type         = "pd-balanced"
  }
}

variable "confidential_compute" {
  type    = bool
  default = false
}

variable "create_template" {
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

variable "metadata" {
  type    = map(string)
  default = {}
}

variable "network_interfaces" {
  type = any
  default = [{
    network    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/default",
    subnetwork = "https://www.googleapis.com/compute/v1/projects/my-project/regions/europe-west1/subnetworks/default-default",
  }]
}

variable "service_account_create" {
  type    = bool
  default = false
}

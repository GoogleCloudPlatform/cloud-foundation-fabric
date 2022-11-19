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

variable "gke_version" {
  type    = string
  default = null
}

variable "labels" {
  type     = map(string)
  default  = {}
  nullable = false
}

variable "max_pods_per_node" {
  type    = number
  default = null
}

variable "node_config" {
  type = any
  default = {
    disk_type = "pd-balanced"
  }
}

variable "node_count" {
  type = any
  default = {
    initial = 1
  }
  nullable = false
}

variable "node_locations" {
  type    = list(string)
  default = null
}

variable "nodepool_config" {
  type    = any
  default = null
}

variable "pod_range" {
  type    = any
  default = null
}

variable "reservation_affinity" {
  type    = any
  default = null
}

variable "service_account_create" {
  type    = bool
  default = false
}

variable "sole_tenant_nodegroup" {
  type    = string
  default = null
}

variable "tags" {
  type    = list(string)
  default = null
}

variable "taints" {
  type    = any
  default = null
}

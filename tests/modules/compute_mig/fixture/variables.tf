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

variable "all_instances_config" {
  type    = any
  default = null
}

variable "auto_healing_policies" {
  type    = any
  default = null
}

variable "autoscaler_config" {
  type    = any
  default = null
}

variable "default_version_name" {
  type    = any
  default = "default"
}

variable "description" {
  type    = any
  default = "Terraform managed."
}

variable "distribution_policy" {
  type    = any
  default = null
}

variable "health_check_config" {
  type    = any
  default = null
}

variable "location" {
  type    = any
  default = "europe-west1-b"
}

variable "named_ports" {
  type    = any
  default = null
}

variable "stateful_disks" {
  type    = any
  default = {}
}

variable "stateful_config" {
  type    = any
  default = {}
}

variable "target_pools" {
  type    = any
  default = []
}

variable "target_size" {
  type    = any
  default = null
}

variable "update_policy" {
  type    = any
  default = null
}

variable "versions" {
  type    = any
  default = {}
}

variable "wait_for_instances" {
  type    = any
  default = null
}

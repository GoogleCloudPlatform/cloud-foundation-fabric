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

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "e2-highcpu-8" # highcpu instances are cheaper than equivalent standard
}

variable "name" {
  description = "Instance name."
  type        = string
}

variable "network_interfaces" {
  description = "Network interfaces configuration."
  type = list(object({
    address    = optional(string)
    name       = string
    network    = string
    routes     = optional(list(string))
    subnetwork = string
  }))
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "tags" {
  description = "Instance network tags for firewall rule targets."
  type        = list(string)
  default     = []
}

variable "zone" {
  description = "Compute zone."
  type        = string
}



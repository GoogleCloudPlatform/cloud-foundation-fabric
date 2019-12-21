/**
 * Copyright 2019 Google LLC
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

variable "addresses" {
  type    = list(string)
  default = []
}

variable "attached_disks" {
  description = "Additional disks (only for non-MIG usage)."
  type = map(object({
    type = string # pd-standard pd-ssd
    size = string
  }))
  default = {}
}

variable "boot_disk" {
  type = object({
    image = string
    size  = number
    type  = string
  })
  default = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
}

variable "cloud_config_path" {
  type = string
}

variable "cloud_config_vars" {
  type    = map(any)
  default = {}
}

variable "docker_log_driver" {
  type    = string
  default = "gcplogs"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "f1-micro"
}

variable "name" {
  type = string
}

variable "network" {
  type = string
}

variable "nat" {
  type = object({
    enabled = bool
    address = string
  })
  default = {
    enabled = false
    address = null
  }
}

variable "options" {
  type = object({
    allow_stopping_for_update = bool
    automatic_restart         = bool
    can_ip_forward            = bool
    on_host_maintenance       = string
  })
  default = {
    allow_stopping_for_update = true
    automatic_restart         = true
    can_ip_forward            = false
    on_host_maintenance       = "MIGRATE"
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account" {
  type    = string
  default = ""
}

variable "stackdriver" {
  type = object({
    enable_logging    = bool
    enable_monitoring = bool
  })
  default = {
    enable_logging    = false
    enable_monitoring = false
  }
}

variable "subnetwork" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = ["ssh"]
}

variable "use_instance_template" {
  type    = bool
  default = false
}

variable "zone" {
  type = string
}

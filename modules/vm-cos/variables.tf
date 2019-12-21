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
  description = "Optional internal addresses (only for non-MIG usage)."
  type        = list(string)
  default     = []
}

variable "attached_disks" {
  description = "Additional disks (only for non-MIG usage)."
  type = map(object({
    type = string
    size = string
  }))
  default = {}
}

variable "boot_disk" {
  description = "Boot disk properties."
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
  description = "Path to cloud config template file to set in metadata."
  type        = string
}

variable "cloud_config_vars" {
  description = "Custom variables passed to cloud config template."
  type        = map(any)
  default     = {}
}

variable "instance_count" {
  description = "Number of instances to create (only for non-MIG usage)."
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "f1-micro"
}

variable "name" {
  description = "Instance name."
  type        = string
}

variable "network" {
  description = "Network name (self link for shared vpc)."
  type        = string
}

variable "nat" {
  description = "External address properties (addresses only for non-MIG usage)."
  type = object({
    enabled   = bool
    addresses = list(string)
  })
  default = {
    enabled   = false
    addresses = []
  }
}

variable "options" {
  description = "Instance options."
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
  description = "Project id."
  type        = string
}

variable "region" {
  description = "Compute region."
  type        = string
}

variable "service_account" {
  description = "Service account email (leave empty to auto-create)."
  type        = string
  default     = ""
}

variable "stackdriver" {
  description = "Stackdriver options set in metadata."
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
  description = "Subnetwork name (self link for shared vpc)."
  type        = string
}

variable "tags" {
  description = "Instance tags."
  type        = list(string)
  default     = ["ssh"]
}

variable "use_instance_template" {
  description = "Create instance template instead of instances."
  type        = bool
  default     = false
}

variable "zone" {
  description = "Compute zone."
  type        = string
}

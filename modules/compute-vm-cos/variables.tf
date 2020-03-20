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

variable "image" {
  description = "Container image."
  type        = string
}

variable "log_driver" {
  description = "Container log driver (local, gcplogs, etc.)."
  type        = string
  default     = "gcplogs"
}

variable "cos_config" {
  description = "Configure COS logging and monitoring."
  type = object({
    logging    = bool
    monitoring = bool
  })
  default = {
    logging    = false
    monitoring = true
  }
}

variable "files" {
  description = "Map of files to create on the instances, path as key. Attributes default to 'root' and '0644', set to null if not needed."
  type = map(object({
    content = string
    attributes = object({
      owner       = string
      permissions = string
    })
  }))
  default = {}
}

variable "hostname" {
  description = "Instance FQDN name."
  type        = string
  default     = null
}

variable "instance_count" {
  description = "Number of instances to create (only for non-template usage)."
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "f1-micro"
}

variable "labels" {
  description = "Instance labels."
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Instance metadata."
  type        = map(string)
  default     = {}
}

variable "min_cpu_platform" {
  description = "Minimum CPU platform."
  type        = string
  default     = null
}

variable "name" {
  description = "Instances base name."
  type        = string
}

variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    nat        = bool
    network    = string
    subnetwork = string
    addresses = object({
      internal = list(string)
      external = list(string)
    })
  }))
}

variable "options" {
  description = "Instance options."
  type = object({
    allow_stopping_for_update = bool
    can_ip_forward            = bool
    deletion_protection       = bool
    preemptible               = bool
  })
  default = {
    allow_stopping_for_update = true
    can_ip_forward            = false
    deletion_protection       = false
    preemptible               = false
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

variable "tags" {
  description = "Instance tags."
  type        = list(string)
  default     = ["dns", "ssh"]
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

variable "volumes" {
  description = "Map of volumes to mount in the container, key is the host path, value is the mount location inside the container"
  type        = map(string)
  default     = {}
}

variable "exposed_ports" {
  description = "Ports to expose in the host"
  type = object({
    tcp = list(number)
    udp = list(number)
  })
  default = {
    tcp = []
    udp = []
  }
}

variable "extra_args" {
  description = "Extra arguments to pass to the container"
  type        = string
  default     = ""
}

variable "pre_runcmds" {
  description = "Extra commands to run (in the host) before starting the container."
  type        = list(string)
  default     = []
}

variable "post_runcmds" {
  description = "Extra commands to run (in the host) after starting the container."
  type        = list(string)
  default     = []
}

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

variable "attached_disks" {
  description = "Additional disks, if options is null defaults will be used in its place. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null."
  type = list(object({
    name        = string
    size        = string
    source      = string
    source_type = string
    options = object({
      auto_delete = bool
      mode        = string
      regional    = bool
      type        = string
    })
  }))
  default = []
  validation {
    condition = length([
      for d in var.attached_disks : d if(
        d.source_type == null
        ||
        contains(["image", "snapshot", "attach"], coalesce(d.source_type, "1"))
      )
    ]) == length(var.attached_disks)
    error_message = "Source type must be one of 'image', 'snapshot', 'attach', null."
  }
}

variable "attached_disk_defaults" {
  description = "Defaults for attached disks options."
  type = object({
    auto_delete = bool
    mode        = string
    regional    = bool
    type        = string
  })
  default = {
    auto_delete = true
    mode        = "READ_WRITE"
    regional    = false
    type        = "pd-ssd"
  }
}

variable "boot_disk" {
  description = "Boot disk properties."
  type = object({
    image = string
    size  = number
    type  = string
  })
  default = {
    image = "projects/debian-cloud/global/images/family/debian-10"
    type  = "pd-ssd"
    size  = 10
  }
}

variable "can_ip_forward" {
  description = "Enable IP forwarding."
  type        = bool
  default     = false
}

variable "confidential_compute" {
  description = "Enable Confidential Compute for these instances."
  type        = bool
  default     = false
}

variable "enable_display" {
  description = "Enable virtual display on the instances"
  type        = bool
  default     = false
}

variable "encryption" {
  description = "Encryption options. Only one of kms_key_self_link and disk_encryption_key_raw may be set. If needed, you can specify to encrypt or not the boot disk."
  type = object({
    encrypt_boot            = bool
    disk_encryption_key_raw = string
    kms_key_self_link       = string
  })
  default = null
}

variable "group" {
  description = "Define this variable to create an instance group for instances. Disabled for template use."
  type = object({
    named_ports = map(number)
  })
  default = null
}

variable "hostname" {
  description = "Instance FQDN name."
  type        = string
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
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

variable "metadata_list" {
  description = "List of instance metadata that will be cycled through. Ignored for template use."
  type        = list(map(string))
  default     = []
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
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses and alias_ips to null if not needed."
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
}

variable "options" {
  description = "Instance options."
  type = object({
    allow_stopping_for_update = bool
    deletion_protection       = bool
    preemptible               = bool
  })
  default = {
    allow_stopping_for_update = true
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

variable "scratch_disks" {
  description = "Scratch disks configuration."
  type = object({
    count     = number
    interface = string
  })
  default = {
    count     = 0
    interface = "NVME"
  }
}

variable "service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

# scopes and scope aliases list
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--scopes
variable "service_account_scopes" {
  description = "Scopes applied to service account."
  type        = list(string)
  default     = []
}

variable "single_name" {
  description = "Do not append progressive count to instance name."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Instance tags."
  type        = list(string)
  default     = []
}

variable "use_instance_template" {
  description = "Create instance template instead of instances."
  type        = bool
  default     = false
}

variable "zones" {
  description = "Compute zone, instance will cycle through the list, defaults to the 'b' zone in the region."
  type        = list(string)
  default     = []
}

variable "shielded_config" {
  description = "Shielded VM configuration of the instances."
  type = object({
    enable_secure_boot          = bool
    enable_vtpm                 = bool
    enable_integrity_monitoring = bool
  })
  default = null
}

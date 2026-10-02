# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "accelerator_config" {
  description = "Hardware accelerator (GPU) configuration."
  type = object({
    core_count = optional(number)
    type       = optional(string)
  })
  default = null
}

variable "boot_disk" {
  description = "Boot disk configuration."
  type = object({
    disk_encryption = optional(string)
    disk_size_gb    = optional(number)
    disk_type       = optional(string)
    kms_key         = optional(string)
  })
  default = null
}

variable "confidential_instance_config" {
  description = "Confidential instance configuration."
  type = object({
    confidential_instance_type = optional(string, "SEV")
  })
  default = null
}

variable "container_image" {
  description = "Container image for the workbench instance."
  type = object({
    repository = string
    tag        = optional(string)
  })
  default = null
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    iam_principals   = optional(map(string), {})
    kms_keys         = optional(map(string), {})
    locations        = optional(map(string), {})
    networks         = optional(map(string), {})
    project_ids      = optional(map(string), {})
    service_accounts = optional(map(string), {})
    subnets          = optional(map(string), {})
  })
  default  = {}
  nullable = false
}

variable "data_disks" {
  description = "Data disk configuration."
  type = object({
    disk_encryption   = optional(string)
    disk_size_gb      = optional(number)
    disk_type         = optional(string)
    kms_key           = optional(string)
    resource_policies = optional(list(string))
  })
  default = null
}

variable "deletion_policy" {
  description = "Deletion policy for workbench instance (DELETE or ABANDON)."
  type        = string
  default     = null
  validation {
    condition = (
      var.deletion_policy == null ||
      contains(["DELETE", "ABANDON"], var.deletion_policy)
    )
    error_message = "deletion_policy must be either DELETE or ABANDON."
  }
}

variable "desired_state" {
  description = "Desired state of Workbench Instance (ACTIVE or STOPPED)."
  type        = string
  default     = null
  validation {
    condition = (
      var.desired_state == null ||
      contains(["ACTIVE", "STOPPED"], var.desired_state)
    )
    error_message = "desired_state must be either ACTIVE or STOPPED."
  }
}

variable "disable_proxy_access" {
  description = "If true, instance will not register with the proxy."
  type        = bool
  default     = false
}

variable "disable_public_ip" {
  description = "If true, no public IP will be assigned to the instance."
  type        = bool
  default     = null
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled for this instance."
  type        = bool
  default     = false
}

variable "enable_ip_forwarding" {
  description = "Flag to enable IP forwarding."
  type        = bool
  default     = null
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "instance_owners" {
  description = "The list of owners of this instance after creation."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels that you can apply to your workbench instances."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "The zone in which the workbench instance should reside."
  type        = string
}

variable "machine_type" {
  description = "The Compute Engine machine type of this instance."
  type        = string
  default     = "e2-standard-4"
}

variable "metadata" {
  description = "Custom metadata to apply to this instance."
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Instance startup script."
  type        = string
  default     = null
}

variable "min_cpu_platform" {
  description = "Minimum CPU platform."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the workbench instance."
  type        = string
}

variable "network_interfaces" {
  description = "The list of network interfaces for the instance."
  type = list(object({
    access_configs = optional(list(object({
      external_ip = optional(string)
    })), [])
    network  = optional(string)
    nic_type = optional(string)
    subnet   = optional(string)
  }))
  default = []
}

variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "reservation_affinity" {
  description = "Reservation affinity configuration."
  type = object({
    consume_reservation_type = string
    key                      = optional(string)
    values                   = optional(list(string))
  })
  default = null
  validation {
    condition = (
      var.reservation_affinity == null ||
      contains(
        ["RESERVATION_NONE", "RESERVATION_ANY", "RESERVATION_SPECIFIC"],
        try(var.reservation_affinity.consume_reservation_type, "")
      )
    )
    error_message = "Invalid consume_reservation_type."
  }
}

variable "service_account" {
  description = "Service account configuration."
  type = object({
    auto_create = optional(bool, false)
    email       = optional(string)
    scopes      = optional(list(string))
  })
  default = null
}

variable "shielded_instance_config" {
  description = "A set of Shielded Instance options."
  type = object({
    enable_integrity_monitoring = optional(bool)
    enable_secure_boot          = optional(bool)
    enable_vtpm                 = optional(bool)
  })
  default = null
}

variable "tags" {
  description = "Compute Engine tags to add to runtime."
  type        = list(string)
  default     = []
}

variable "vm_image" {
  description = "Custom Compute Engine VM image to use."
  type = object({
    family  = optional(string)
    name    = optional(string)
    project = optional(string)
  })
  default = null
}

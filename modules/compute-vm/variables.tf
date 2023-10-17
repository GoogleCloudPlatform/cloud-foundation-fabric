/**
 * Copyright 2023 Google LLC
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

variable "attached_disk_defaults" {
  description = "Defaults for attached disks options."
  type = object({
    auto_delete  = optional(bool, false)
    mode         = string
    replica_zone = string
    type         = string
  })
  default = {
    auto_delete  = true
    mode         = "READ_WRITE"
    replica_zone = null
    type         = "pd-balanced"
  }
  validation {
    condition     = var.attached_disk_defaults.mode == "READ_WRITE" || !var.attached_disk_defaults.auto_delete
    error_message = "auto_delete can only be specified on READ_WRITE disks."
  }
}

variable "attached_disks" {
  description = "Additional disks, if options is null defaults will be used in its place. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null."
  type = list(object({
    name        = string
    device_name = optional(string)
    # TODO: size can be null when source_type is attach
    size              = string
    snapshot_schedule = optional(string)
    source            = optional(string)
    source_type       = optional(string)
    options = optional(
      object({
        auto_delete  = optional(bool, false)
        mode         = optional(string, "READ_WRITE")
        replica_zone = optional(string)
        type         = optional(string, "pd-balanced")
      }),
      {
        auto_delete  = true
        mode         = "READ_WRITE"
        replica_zone = null
        type         = "pd-balanced"
      }
    )
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

  validation {
    condition = length([
      for d in var.attached_disks : d if d.options == null ||
      d.options.mode == "READ_WRITE" || !d.options.auto_delete
    ]) == length(var.attached_disks)
    error_message = "auto_delete can only be specified on READ_WRITE disks."
  }
}

variable "boot_disk" {
  description = "Boot disk properties."
  type = object({
    auto_delete       = optional(bool, true)
    snapshot_schedule = optional(string)
    source            = optional(string)
    initialize_params = optional(object({
      image = optional(string, "projects/debian-cloud/global/images/family/debian-11")
      size  = optional(number, 10)
      type  = optional(string, "pd-balanced")
    }))
    use_independent_disk = optional(bool, false)
  })
  default = {
    initialize_params = {}
  }
  nullable = false
  validation {
    condition = (
      (var.boot_disk.source == null ? 0 : 1) +
      (var.boot_disk.initialize_params == null ? 0 : 1) < 2
    )
    error_message = "You can only have one of boot disk source or initialize params."
  }
  validation {
    condition = (
      var.boot_disk.use_independent_disk != true
      ||
      var.boot_disk.initialize_params != null
    )
    error_message = "Using an independent disk for boot requires initialize params."
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

variable "create_template" {
  description = "Create instance template instead of instances."
  type        = bool
  default     = false
}
variable "description" {
  description = "Description of a Compute Instance."
  type        = string
  default     = "Managed by the compute-vm Terraform module."
}

variable "enable_display" {
  description = "Enable virtual display on the instances."
  type        = bool
  default     = false
}

variable "encryption" {
  description = "Encryption options. Only one of kms_key_self_link and disk_encryption_key_raw may be set. If needed, you can specify to encrypt or not the boot disk."
  type = object({
    encrypt_boot            = optional(bool, false)
    disk_encryption_key_raw = optional(string)
    kms_key_self_link       = optional(string)
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

variable "instance_schedule" {
  description = "Assign or create and assign an instance schedule policy. Either resource policy id or create_config must be specified if not null. Set active to null to dtach a policy from vm before destroying."
  type = object({
    resource_policy_id = optional(string)
    create_config = optional(object({
      active          = optional(bool, true)
      description     = optional(string)
      expiration_time = optional(string)
      start_time      = optional(string)
      timezone        = optional(string, "UTC")
      vm_start        = optional(string)
      vm_stop         = optional(string)
    }))
  })
  default = null
  validation {
    condition = (
      var.instance_schedule == null ||
      try(var.instance_schedule.resource_policy_id, null) != null ||
      try(var.instance_schedule.create_config, null) != null
    )
    error_message = "A resource policy name or configuration must be specified when not null."
  }
  validation {
    condition = (
      try(var.instance_schedule.create_config, null) == null ||
      length(compact([
        try(var.instance_schedule.create_config.vm_start, null),
        try(var.instance_schedule.create_config.vm_stop, null)
      ])) > 0
    )
    error_message = "A resource policy configuration must contain at least one schedule."
  }
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
  description = "Instance name."
  type        = string
}

variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    network    = string
    subnetwork = string
    alias_ips  = optional(map(string), {})
    nat        = optional(bool, false)
    nic_type   = optional(string)
    stack_type = optional(string)
    addresses = optional(object({
      internal = optional(string)
      external = optional(string)
    }), null)
  }))
}

variable "options" {
  description = "Instance options."
  type = object({
    allow_stopping_for_update = optional(bool, true)
    deletion_protection       = optional(bool, false)
    spot                      = optional(bool, false)
    termination_action        = optional(string)
  })
  default = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = false
    termination_action        = null
  }
  validation {
    condition = (var.options.termination_action == null
      ||
    contains(["STOP", "DELETE"], coalesce(var.options.termination_action, "1")))
    error_message = "Allowed values for options.termination_action are 'STOP', 'DELETE' and null."
  }
}

variable "project_id" {
  description = "Project id."
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
  description = "Service account email and scopes. If email is null, the default Compute service account will be used unless auto_create is true, in which case a service account will be created. Set the variable to null to avoid attaching a service account."
  type = object({
    auto_create = optional(bool, false)
    email       = optional(string)
    scopes      = optional(list(string))
  })
  default = {}
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

variable "snapshot_schedules" {
  description = "Snapshot schedule resource policies that can be attached to disks."
  type = map(object({
    schedule = object({
      daily = optional(object({
        days_in_cycle = number
        start_time    = string
      }))
      hourly = optional(object({
        hours_in_cycle = number
        start_time     = string
      }))
      weekly = optional(list(object({
        day        = string
        start_time = string
      })))
    })
    description = optional(string)
    retention_policy = optional(object({
      max_retention_days         = number
      on_source_disk_delete_keep = optional(bool)
    }))
    snapshot_properties = optional(object({
      chain_name        = optional(string)
      guest_flush       = optional(bool)
      labels            = optional(map(string))
      storage_locations = optional(list(string))
    }))
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.snapshot_schedules : (
        (v.schedule.daily != null ? 1 : 0) +
        (v.schedule.hourly != null ? 1 : 0) +
        (v.schedule.weekly != null ? 1 : 0)
      ) == 1
    ])
    error_message = "Schedule must contain exactly one of daily, hourly, or weekly schedule."
  }
}

variable "tag_bindings" {
  description = "Tag bindings for this instance, in tag key => tag value format."
  type        = map(string)
  default     = null
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

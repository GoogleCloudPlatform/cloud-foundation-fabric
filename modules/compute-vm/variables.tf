/**
 * Copyright 2026 Google LLC
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
  description = "Additional disks. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null."
  type = map(object({
    auto_delete  = optional(bool, true) # applies only to vm templates
    device_name  = optional(string)
    force_attach = optional(bool)
    position     = optional(string)
    # auto_delete can only be specified for READ_WRITE, force null otherwise
    mode = optional(string, "READ_WRITE")
    name = optional(string)
    initialize_params = optional(object({
      replica_zone = optional(string)
      size         = optional(number, 10)
      type         = optional(string, "pd-balanced")
      hyperdisk = optional(object({
        provisioned_iops       = optional(number)
        provisioned_throughput = optional(number) # in MiB/s
        storage_pool           = optional(string)
      }), {})
    }), {})
    snapshot_schedule = optional(list(string))
    source = optional(object({
      attach = optional(string)
      # disk             = optional(string)
      image = optional(string) # not supported yet for repd
      # instant_snapshot = optional(string)
      snapshot = optional(string)
    }), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.attached_disks :
      contains(["READ_WRITE", "READ_ONLY"], v.mode)
    ])
    error_message = "Allowed values for 'mode' are 'READ_WRITE', 'READ_ONLY'."
  }
}

variable "boot_disk" {
  description = "Boot disk properties."
  type = object({
    architecture      = optional(string)
    auto_delete       = optional(bool, true)
    force_attach      = optional(bool)
    snapshot_schedule = optional(list(string))
    initialize_params = optional(object({
      size = optional(number, 10)
      type = optional(string, "pd-balanced")
      hyperdisk = optional(object({
        provisioned_iops       = optional(number)
        provisioned_throughput = optional(number) # in MiB/s
        storage_pool           = optional(string)
      }), {})
    }), {})
    source = optional(object({
      attach = optional(string)
      disk   = optional(string)
      image  = optional(string)
      # instant_snapshot = optional(string)
      snapshot = optional(string)
    }), { image = "debian-cloud/debian-13" })
    use_independent_disk = optional(object({
      name = optional(string)
    }))
  })
  default  = {}
  nullable = false
  validation {
    condition = (
      var.boot_disk.initialize_params == null ||
      (
        var.boot_disk.source.attach == null &&
        var.boot_disk.source.snapshot == null &&
        var.boot_disk.source.disk == null
      )
    )
    error_message = "Initialize params cannot be used when attaching an existing disk or creating from a snapshot."
  }
  validation {
    condition = (
      var.boot_disk.use_independent_disk == null
      ||
      var.boot_disk.initialize_params != null
    )
    error_message = "Using an independent disk for boot requires initialize params."
  }
  validation {
    condition = (
      var.boot_disk.architecture == null ||
      contains(["ARM64", "X86_64"], var.boot_disk.architecture)
    )
    error_message = "Architecture can be null, 'X86_64' or 'ARM64'."
  }
}

variable "can_ip_forward" {
  description = "Enable IP forwarding."
  type        = bool
  default     = false
}

variable "confidential_compute" {
  description = "Confidential Compute configuration. Set to 'SEV' or 'SEV_SNP' to enable."
  type        = string
  default     = null
  validation {
    condition     = var.confidential_compute == null || contains(["SEV", "SEV_SNP"], var.confidential_compute)
    error_message = "Allowed values are 'SEV' or 'SEV_SNP'."
  }
}

variable "context" {
  description = "Context-specific interpolations."
  type = object({
    addresses      = optional(map(string), {})
    custom_roles   = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    iam_principals = optional(map(string), {})
    locations      = optional(map(string), {})
    networks       = optional(map(string), {})
    project_ids    = optional(map(string), {})
    subnets        = optional(map(string), {})
    tag_values     = optional(map(string), {})
    tag_vars = optional(object({
      projects     = optional(map(map(string)), {})
      organization = optional(map(string), {})
    }), {})
  })
  default  = {}
  nullable = false
}

variable "create_template" {
  description = "Create instance template instead of instances. Defaults to a global template."
  type = object({
    regional = optional(bool, false)
  })
  nullable = true
  default  = null
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
  # TODO: Add validation to enforce exclusivity of kms_key_self_link and disk_encryption_key_raw
  type = object({
    encrypt_boot            = optional(bool, false)
    disk_encryption_key_raw = optional(string)
    kms_key_self_link       = optional(string)
  })
  default = null
}

variable "gpu" {
  description = "GPU information. Based on https://cloud.google.com/compute/docs/gpus."
  type = object({
    count = number
    type  = string
  })
  default = null

  validation {
    condition = (
      var.gpu == null ||
      contains(
        [
          "nvidia-tesla-a100",
          "nvidia-tesla-p100",
          "nvidia-tesla-p100-vws",
          "nvidia-tesla-v100",
          "nvidia-tesla-p4",
          "nvidia-tesla-p4-vws",
          "nvidia-tesla-t4",
          "nvidia-tesla-t4-vws",
          "nvidia-l4",
          "nvidia-l4-vws",
          "nvidia-a100-80gb",
          "nvidia-h100-80gb",
          "nvidia-h100-mega-80gb",
          "nvidia-h200-141gb"
        ],
        try(var.gpu.type, "-")
      )
    )
    error_message = "GPU type must be one of the allowed values: nvidia-tesla-a100, nvidia-tesla-p100, nvidia-tesla-p100-vws, nvidia-tesla-v100, nvidia-tesla-p4, nvidia-tesla-p4-vws, nvidia-tesla-t4, nvidia-tesla-t4-vws, nvidia-l4, nvidia-l4-vws,  nvidia-a100-80gb, nvidia-h100-80gb, nvidia-h100-mega-80gb, nvidia-h200-141gb."
  }
}

variable "group" {
  description = "Instance group configuration. Set 'named_ports' to create a new unmanaged instance group, or provide an existing group self_link/id in 'membership' to join one."
  type = object({
    membership  = optional(string) # ID of an existing unmanaged group to join
    named_ports = optional(map(number), {})
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
  description = "Assign or create and assign an instance schedule policy. Set active to null to detach a policy from vm before destroying."
  type = object({
    active          = optional(bool, true)
    description     = optional(string)
    expiration_time = optional(string)
    start_time      = optional(string)
    timezone        = optional(string, "UTC")
    vm_start        = optional(string)
    vm_stop         = optional(string)
  })
  default = null
  validation {
    condition = (
      var.instance_schedule == null ||
      length(compact([
        try(var.instance_schedule.vm_start, null),
        try(var.instance_schedule.vm_stop, null)
      ])) > 0
    )
    error_message = "An instance schedule must contain at least one schedule."
  }
}

variable "kms_autokeys" {
  description = "KMS Autokey key handles. If location is not specified it will be inferred from the zone. Key handle names will be added to the kms_keys context with an `autokeys/` prefix."
  type = map(object({
    location               = optional(string)
    resource_type_selector = optional(string, "compute.googleapis.com/Disk")
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.kms_autokeys : k == try(regex(
        "^[a-z][a-z0-9-]+[a-z0-9]$", k
      ), null)
    ])
    error_message = "Autokey keys need to be valid GCP resource names."
  }
}

variable "labels" {
  description = "Instance labels."
  type        = map(string)
  default     = {}
}

variable "lifecycle_config" {
  description = "Instance lifecycle and operational configurations."
  type = object({
    allow_stopping_for_update  = optional(bool, true)
    deletion_protection        = optional(bool, false)
    key_revocation_action_type = optional(string)
    graceful_shutdown = optional(object({
      enabled           = optional(bool, false)
      max_duration_secs = optional(number)
    }))
  })
  default = {}
  validation {
    condition = (
      var.lifecycle_config.key_revocation_action_type == null || contains(
        ["NONE", "STOP"], var.lifecycle_config.key_revocation_action_type
      )
    )
    error_message = "Allowed values for key_revocation_action_type are 'NONE' or 'STOP'."
  }
}

variable "machine_features_config" {
  description = "Machine-level configuration."
  type = object({
    enable_nested_virtualization = optional(bool)
    enable_turbo_mode            = optional(bool)
    enable_uefi_networking       = optional(bool)
    performance_monitoring_unit  = optional(string)
    threads_per_core             = optional(number)
    visible_core_count           = optional(number)
  })
  nullable = false
  default  = {}
  validation {
    condition = (
      try(var.machine_features_config.performance_monitoring_unit, null) == null ||
      contains(
        ["ARCHITECTURAL", "ENHANCED", "STANDARD"],
        coalesce(try(var.machine_features_config.performance_monitoring_unit, null), "-")
      )
    )
    error_message = "Allowed values for performance_monitoring_unit are ARCHITECTURAL', 'ENHANCED', 'STANDARD' and null."
  }
}

variable "machine_type" {
  description = "Machine type."
  type        = string
  default     = "e2-micro"
}

variable "metadata" {
  description = "Instance metadata."
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Instance startup script. Will trigger recreation on change, even after importing."
  type        = string
  nullable    = true
  default     = null
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

variable "network_attached_interfaces" {
  description = "Network interfaces using network attachments."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "network_interfaces" {
  description = "Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed."
  type = list(object({
    network                     = string
    subnetwork                  = string
    alias_ips                   = optional(map(string), {})
    nat                         = optional(bool, false)
    network_tier                = optional(string)
    nic_type                    = optional(string)
    stack_type                  = optional(string)
    queue_count                 = optional(number) # NEW
    internal_ipv6_prefix_length = optional(number) # NEW
    addresses = optional(object({
      internal = optional(string)
      external = optional(string)
    }), null)
  }))
  validation {
    condition     = alltrue([for v in var.network_interfaces : contains(["STANDARD", "PREMIUM"], coalesce(v.network_tier, "PREMIUM"))])
    error_message = "Allowed values for network tier are: 'STANDARD' or 'PREMIUM'"
  }
}

variable "network_performance_tier" {
  description = "Network performance total egress bandwidth tier."
  type        = string
  default     = null
  validation {
    condition     = var.network_performance_tier == null || contains(["DEFAULT", "TIER_1"], coalesce(var.network_performance_tier, "-"))
    error_message = "Allowed values are 'DEFAULT' or 'TIER_1'."
  }
}

variable "network_tag_bindings" {
  description = "Resource manager tag bindings in arbitrary key => tag key or value id format. Set on both the instance only for networking purposes, and modifiable without impacting the main resource lifecycle."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "project_id" {
  description = "Project id."
  type        = string
}

variable "project_number" {
  description = "Project number. Used in tag bindings to avoid a permadiff."
  type        = string
  default     = null
}

variable "resource_policies" {
  description = "Resource policies to attach to the instance or template."
  type        = list(string)
  nullable    = true
  default     = null
}

variable "scheduling_config" {
  description = "Scheduling configuration for the instance."
  type = object({
    automatic_restart    = optional(bool)   # Defaults to !spot
    maintenance_interval = optional(string) # NEW
    min_node_cpus        = optional(number) # NEW
    on_host_maintenance  = optional(string) # Defaults to MIGRATE or TERMINATE based on GPU/Spot
    provisioning_model   = optional(string) # "SPOT" or "STANDARD"
    termination_action   = optional(string)
    local_ssd_recovery_timeout = optional(object({ # NEW
      nanos   = optional(number)
      seconds = number
    }))
    max_run_duration = optional(object({
      nanos   = optional(number)
      seconds = number
    }))
    node_affinities = optional(map(object({
      values = list(string)
      in     = optional(bool, true)
    })), {})
  })
  nullable = false
  default  = {}
  validation {
    condition = (
      var.scheduling_config.termination_action == null || contains(
        ["STOP", "DELETE"], coalesce(var.scheduling_config.termination_action, "1"
        )
      )
    )
    error_message = "Allowed values for termination_action are 'STOP', 'DELETE' and null."
  }
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
    enable_secure_boot          = optional(bool, true)
    enable_vtpm                 = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
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
  description = "Resource manager tag bindings in arbitrary key => tag key or value id format. Set on both the instance and zonal disks, and modifiable without impacting the main resource lifecycle."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "tag_bindings_immutable" {
  description = "Immutable resource manager tag bindings, in tagKeys/id => tagValues/id format. These are set on the instance or instance template at creation time, and trigger recreation if changed."
  type        = map(string)
  nullable    = true
  default     = null
  validation {
    condition = alltrue([
      for k, v in coalesce(var.tag_bindings_immutable, {}) :
      startswith(k, "tagKeys/") && startswith(v, "tagValues/")
    ])
    error_message = "Incorrect format for immutable tag bindings."
  }
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

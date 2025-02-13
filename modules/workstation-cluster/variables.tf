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

variable "annotations" {
  description = "Workstation cluster annotations."
  type        = map(string)
  default     = {}
}

variable "display_name" {
  description = "Display name."
  type        = string
  default     = null
}

variable "domain" {
  description = "Domain."
  type        = string
  default     = null
}

variable "id" {
  description = "Workstation cluster ID."
  type        = string
}

variable "labels" {
  description = "Workstation cluster labels."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Location."
  type        = string
}

variable "network_config" {
  description = "Network configuration."
  type = object({
    network    = string
    subnetwork = string
  })
}

variable "private_cluster_config" {
  description = "Private cluster config."
  type = object({
    enable_private_endpoint = optional(bool, false)
    allowed_projects        = optional(list(string))
  })
  nullable = false
  default  = {}
}

variable "project_id" {
  description = "Cluster ID."
  type        = string
}

variable "workstation_configs" {
  description = "Workstation configurations."
  type = map(object({
    annotations = optional(map(string))
    container = optional(object({
      image       = optional(string)
      command     = optional(list(string), [])
      args        = optional(list(string), [])
      working_dir = optional(string)
      env         = optional(map(string), {})
      run_as_user = optional(string)
    }))
    display_name       = optional(string)
    enable_audit_agent = optional(bool)
    encryption_key = optional(object({
      kms_key                 = string
      kms_key_service_account = string
    }))
    gce_instance = optional(object({
      machine_type                 = optional(string)
      service_account              = optional(string)
      service_account_scopes       = optional(list(string), [])
      pool_size                    = optional(number)
      boot_disk_size_gb            = optional(number)
      tags                         = optional(list(string))
      disable_public_ip_addresses  = optional(bool, false)
      enable_nested_virtualization = optional(bool, false)
      shielded_instance_config = optional(object({
        enable_secure_boot          = optional(bool, false)
        enable_vtpm                 = optional(bool, false)
        enable_integrity_monitoring = optional(bool, false)
      }))
      enable_confidential_compute = optional(bool, false)
      accelerators = optional(list(object({
        type  = optional(string)
        count = optional(number)
      })), [])
    }))
    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      role    = string
      members = list(string)
    })), {})
    iam_bindings_additive = optional(map(object({
      role   = string
      member = string
    })), {})
    idle_timeout = optional(string)
    labels       = optional(map(string))
    persistent_directories = optional(list(object({
      mount_path = optional(string)
      gce_pd = optional(object({
        size_gb         = optional(number)
        fs_type         = optional(string)
        disk_type       = optional(string)
        source_snapshot = optional(string)
        reclaim_policy  = optional(string)
      }))
    })), [])
    running_timeout = optional(string)
    replica_zones   = optional(list(string))
    workstations = optional(map(object({
      annotations  = optional(map(string))
      display_name = optional(string)
      env          = optional(map(string))
      iam          = optional(map(list(string)), {})
      iam_bindings = optional(map(object({
        role    = string
        members = list(string)
      })), {})
      iam_bindings_additive = optional(map(object({
        role   = string
        member = string
      })), {})
      labels = optional(map(string))
    })), {})
  }))
}

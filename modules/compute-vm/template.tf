/**
 * Copyright 2025 Google LLC
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

locals {
  template_create   = var.create_template != null
  template_regional = try(var.create_template.regional, null) == true
}

resource "google_compute_instance_template" "default" {
  provider                = google-beta
  count                   = local.template_create && !local.template_regional ? 1 : 0
  project                 = var.project_id
  region                  = local.region
  name_prefix             = "${var.name}-"
  description             = var.description
  tags                    = var.tags
  machine_type            = var.instance_type
  min_cpu_platform        = var.min_cpu_platform
  can_ip_forward          = var.can_ip_forward
  metadata                = var.metadata
  metadata_startup_script = var.metadata_startup_script
  labels                  = var.labels
  resource_manager_tags   = var.tag_bindings_immutable
  resource_policies = (
    var.resource_policies == null && var.instance_schedule == null
    ? null
    : concat(
      coalesce(var.resource_policies, []),
      coalesce(local.ischedule, [])
    )
  )
  dynamic "advanced_machine_features" {
    for_each = local.advanced_mf != null ? [""] : []
    content {
      enable_nested_virtualization = local.advanced_mf.enable_nested_virtualization
      enable_uefi_networking       = local.advanced_mf.enable_uefi_networking
      performance_monitoring_unit  = local.advanced_mf.performance_monitoring_unit
      threads_per_core             = local.advanced_mf.threads_per_core
      turbo_mode = (
        local.advanced_mf.enable_turbo_mode ? "ALL_CORE_MAX" : null
      )
      visible_core_count = local.advanced_mf.visible_core_count
    }
  }

  disk {
    auto_delete           = var.boot_disk.auto_delete
    boot                  = true
    disk_size_gb          = var.boot_disk.initialize_params.size
    disk_type             = var.boot_disk.initialize_params.type
    resource_manager_tags = var.tag_bindings_immutable
    source_image          = var.boot_disk.initialize_params.image

    dynamic "disk_encryption_key" {
      for_each = var.encryption != null ? [""] : []
      content {
        kms_key_self_link = var.encryption.kms_key_self_link
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_compute ? [""] : []
    content {
      enable_confidential_compute = true
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.gpu ? [var.gpu] : []
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }
  dynamic "disk" {
    for_each = local.attached_disks
    iterator = config
    content {
      auto_delete = config.value.options.auto_delete
      device_name = coalesce(
        config.value.device_name, config.value.name, config.key
      )
      # Cannot use `source` with any of the fields in
      # [disk_size_gb disk_name disk_type source_image labels]
      disk_type = (
        config.value.source_type != "attach" ? config.value.options.type : null
      )
      disk_size_gb = (
        config.value.source_type != "attach" ? config.value.size : null
      )
      mode = config.value.options.mode
      source_image = (
        config.value.source_type == "image" ? config.value.source : null
      )
      source = (
        config.value.source_type == "attach" ? config.value.source : null
      )
      disk_name = (
        config.value.source_type != "attach" ? config.value.name : null
      )
      resource_manager_tags = var.tag_bindings_immutable
      type                  = "PERSISTENT"
      dynamic "disk_encryption_key" {
        for_each = var.encryption != null ? [""] : []
        content {
          kms_key_self_link = var.encryption.kms_key_self_link
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      network_ip = try(config.value.addresses.internal, null)
      nic_type   = config.value.nic_type
      stack_type = config.value.stack_type
      dynamic "access_config" {
        for_each = config.value.nat ? [""] : []
        content {
          nat_ip = try(config.value.addresses.external, null)
        }
      }
      dynamic "alias_ip_range" {
        for_each = config.value.alias_ips
        iterator = config_alias
        content {
          subnetwork_range_name = config_alias.key
          ip_cidr_range         = config_alias.value
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_attached_interfaces
    content {
      network_attachment = network_interface.value
    }
  }

  scheduling {
    automatic_restart           = !var.options.spot
    instance_termination_action = local.termination_action
    on_host_maintenance         = local.on_host_maintenance
    preemptible                 = var.options.spot
    provisioning_model          = var.options.spot ? "SPOT" : "STANDARD"
    dynamic "max_run_duration" {
      for_each = var.options.max_run_duration == null ? [] : [""]
      content {
        nanos   = var.options.max_run_duration.nanos
        seconds = var.options.max_run_duration.seconds
      }
    }

    dynamic "node_affinities" {
      for_each = var.options.node_affinities
      iterator = affinity
      content {
        key      = affinity.key
        operator = affinity.value.in ? "IN" : "NOT_IN"
        values   = affinity.value.values
      }
    }

    dynamic "graceful_shutdown" {
      for_each = var.options.graceful_shutdown != null ? [""] : []
      content {
        enabled = var.options.graceful_shutdown.enabled
        dynamic "max_duration" {
          for_each = var.options.graceful_shutdown.enabled == true && var.options.graceful_shutdown.max_duration_secs != null ? [""] : []
          content {
            seconds = var.options.graceful_shutdown.max_duration_secs
            nanos   = 0
          }
        }
      }
    }
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [""]
    content {
      email  = local.service_account.email
      scopes = local.service_account.scopes
    }
  }

  dynamic "shielded_instance_config" {
    for_each = var.shielded_config != null ? [var.shielded_config] : []
    iterator = config
    content {
      enable_secure_boot          = config.value.enable_secure_boot
      enable_vtpm                 = config.value.enable_vtpm
      enable_integrity_monitoring = config.value.enable_integrity_monitoring
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_template" "default" {
  provider                = google-beta
  count                   = local.template_create && local.template_regional ? 1 : 0
  project                 = var.project_id
  region                  = local.region
  name_prefix             = "${var.name}-"
  description             = var.description
  tags                    = var.tags
  machine_type            = var.instance_type
  min_cpu_platform        = var.min_cpu_platform
  can_ip_forward          = var.can_ip_forward
  metadata                = var.metadata
  metadata_startup_script = var.metadata_startup_script
  labels                  = var.labels
  resource_manager_tags   = var.tag_bindings_immutable
  resource_policies = (
    var.resource_policies == null && var.instance_schedule == null
    ? null
    : concat(
      coalesce(var.resource_policies, []),
      coalesce(local.ischedule, [])
    )
  )
  dynamic "advanced_machine_features" {
    for_each = local.advanced_mf != null ? [""] : []
    content {
      enable_nested_virtualization = local.advanced_mf.enable_nested_virtualization
      enable_uefi_networking       = local.advanced_mf.enable_uefi_networking
      performance_monitoring_unit  = local.advanced_mf.performance_monitoring_unit
      threads_per_core             = local.advanced_mf.threads_per_core
      turbo_mode = (
        local.advanced_mf.enable_turbo_mode ? "ALL_CORE_MAX" : null
      )
      visible_core_count = local.advanced_mf.visible_core_count
    }
  }

  disk {
    auto_delete           = var.boot_disk.auto_delete
    boot                  = true
    disk_size_gb          = var.boot_disk.initialize_params.size
    disk_type             = var.boot_disk.initialize_params.type
    resource_manager_tags = var.tag_bindings_immutable
    source_image          = var.boot_disk.initialize_params.image

    dynamic "disk_encryption_key" {
      for_each = var.encryption != null ? [""] : []
      content {
        kms_key_self_link = var.encryption.kms_key_self_link
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_compute ? [""] : []
    content {
      enable_confidential_compute = true
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.gpu ? [var.gpu] : []
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }
  dynamic "disk" {
    for_each = local.attached_disks
    iterator = config
    content {
      auto_delete = config.value.options.auto_delete
      device_name = coalesce(
        config.value.device_name, config.value.name, config.key
      )
      # Cannot use `source` with any of the fields in
      # [disk_size_gb disk_name disk_type source_image labels]
      disk_type = (
        config.value.source_type != "attach" ? config.value.options.type : null
      )
      disk_size_gb = (
        config.value.source_type != "attach" ? config.value.size : null
      )
      mode = config.value.options.mode
      source_image = (
        config.value.source_type == "image" ? config.value.source : null
      )
      source = (
        config.value.source_type == "attach" ? config.value.source : null
      )
      disk_name = (
        config.value.source_type != "attach" ? config.value.name : null
      )
      resource_manager_tags = var.tag_bindings_immutable
      type                  = "PERSISTENT"
      dynamic "disk_encryption_key" {
        for_each = var.encryption != null ? [""] : []
        content {
          kms_key_self_link = var.encryption.kms_key_self_link
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      network_ip = try(config.value.addresses.internal, null)
      nic_type   = config.value.nic_type
      stack_type = config.value.stack_type
      dynamic "access_config" {
        for_each = config.value.nat ? [""] : []
        content {
          nat_ip = try(config.value.addresses.external, null)
        }
      }
      dynamic "alias_ip_range" {
        for_each = config.value.alias_ips
        iterator = config_alias
        content {
          subnetwork_range_name = config_alias.key
          ip_cidr_range         = config_alias.value
        }
      }
    }
  }

  scheduling {
    automatic_restart           = !var.options.spot
    instance_termination_action = local.termination_action
    on_host_maintenance         = local.on_host_maintenance
    preemptible                 = var.options.spot
    provisioning_model          = var.options.spot ? "SPOT" : "STANDARD"
    dynamic "max_run_duration" {
      for_each = var.options.max_run_duration == null ? [] : [""]
      content {
        nanos   = var.options.max_run_duration.nanos
        seconds = var.options.max_run_duration.seconds
      }
    }

    dynamic "node_affinities" {
      for_each = var.options.node_affinities
      iterator = affinity
      content {
        key      = affinity.key
        operator = affinity.value.in ? "IN" : "NOT_IN"
        values   = affinity.value.values
      }
    }

    dynamic "graceful_shutdown" {
      for_each = var.options.graceful_shutdown != null ? [""] : []
      content {
        enabled = var.options.graceful_shutdown.enabled
        dynamic "max_duration" {
          for_each = var.options.graceful_shutdown.enabled == true && var.options.graceful_shutdown.max_duration_secs != null ? [""] : []
          content {
            seconds = var.options.graceful_shutdown.max_duration_secs
            nanos   = 0
          }
        }
      }
    }
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [""]
    content {
      email  = local.service_account.email
      scopes = local.service_account.scopes
    }
  }

  dynamic "shielded_instance_config" {
    for_each = var.shielded_config != null ? [var.shielded_config] : []
    iterator = config
    content {
      enable_secure_boot          = config.value.enable_secure_boot
      enable_vtpm                 = config.value.enable_vtpm
      enable_integrity_monitoring = config.value.enable_integrity_monitoring
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

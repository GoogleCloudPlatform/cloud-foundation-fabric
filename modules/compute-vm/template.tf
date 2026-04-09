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

locals {
  is_template       = var.create_template != null
  template_regional = try(var.create_template.regional, null) == true
}

resource "google_compute_instance_template" "default" {
  provider                   = google-beta
  count                      = local.is_template && !local.template_regional ? 1 : 0
  project                    = local.project_id
  region                     = local.region
  name_prefix                = "${var.name}-"
  description                = var.description
  tags                       = var.tags
  machine_type               = var.machine_type
  min_cpu_platform           = var.min_cpu_platform
  can_ip_forward             = var.can_ip_forward
  metadata                   = var.metadata
  metadata_startup_script    = var.metadata_startup_script
  labels                     = var.labels
  resource_manager_tags      = var.tag_bindings_immutable
  key_revocation_action_type = var.lifecycle_config.key_revocation_action_type
  resource_policies = (
    var.resource_policies == null && var.instance_schedule == null
    ? null
    : concat(
      coalesce(var.resource_policies, []),
      coalesce(local.ischedule, [])
    )
  )
  dynamic "advanced_machine_features" {
    for_each = local.advanced_mf ? [""] : []
    content {
      enable_nested_virtualization = var.machine_features_config.enable_nested_virtualization
      enable_uefi_networking       = var.machine_features_config.enable_uefi_networking
      performance_monitoring_unit  = var.machine_features_config.performance_monitoring_unit
      threads_per_core             = var.machine_features_config.threads_per_core
      turbo_mode = (
        var.machine_features_config.enable_turbo_mode == true ? "ALL_CORE_MAX" : null
      )
      visible_core_count = var.machine_features_config.visible_core_count
    }
  }

  disk {
    boot                   = true
    architecture           = var.boot_disk.architecture
    auto_delete            = var.boot_disk.auto_delete
    disk_size_gb           = var.boot_disk.initialize_params.size
    disk_type              = var.boot_disk.initialize_params.type
    source_image           = var.boot_disk.source.image
    provisioned_iops       = var.boot_disk.initialize_params.hyperdisk.provisioned_iops
    provisioned_throughput = var.boot_disk.initialize_params.hyperdisk.provisioned_throughput
    resource_manager_tags  = var.tag_bindings_immutable

    dynamic "disk_encryption_key" {
      for_each = var.encryption != null ? [""] : []
      content {
        kms_key_self_link = lookup(
          local.ctx_kms_keys,
          var.encryption.kms_key_self_link,
          var.encryption.kms_key_self_link
        )
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_compute != null ? [""] : []
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
    for_each = local.attached_disks_ordered
    iterator = disk_iter
    content {
      architecture = var.boot_disk.architecture
      auto_delete  = var.attached_disks[disk_iter.value.key].mode == "READ_ONLY" ? null : var.attached_disks[disk_iter.value.key].auto_delete
      device_name  = coalesce(var.attached_disks[disk_iter.value.key].device_name, var.attached_disks[disk_iter.value.key].name, disk_iter.value.key)
      disk_name = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? coalesce(var.attached_disks[disk_iter.value.key].name, disk_iter.value.key)
        : null
      )
      mode                  = var.attached_disks[disk_iter.value.key].mode
      resource_manager_tags = var.tag_bindings_immutable
      source_image          = var.attached_disks[disk_iter.value.key].source.image
      source                = var.attached_disks[disk_iter.value.key].source.attach
      type                  = "PERSISTENT"
      # Cannot use `source` with any of the fields in
      # [disk_size_gb disk_name disk_type source_image labels]
      disk_type = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? var.attached_disks[disk_iter.value.key].initialize_params.type
        : null
      )
      disk_size_gb = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? var.attached_disks[disk_iter.value.key].initialize_params.size
        : null
      )
      provisioned_iops = (
        var.attached_disks[disk_iter.value.key].initialize_params.hyperdisk.provisioned_iops
      )
      provisioned_throughput = (
        var.attached_disks[disk_iter.value.key].initialize_params.hyperdisk.provisioned_throughput
      )
      dynamic "disk_encryption_key" {
        for_each = var.encryption != null ? [""] : []
        content {
          kms_key_self_link = lookup(
            local.ctx_kms_keys,
            var.encryption.kms_key_self_link,
            var.encryption.kms_key_self_link
          )
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    iterator = config
    content {
      network = lookup(
        local.ctx.networks, config.value.network, config.value.network
      )
      subnetwork = lookup(
        local.ctx.subnets, config.value.subnetwork, config.value.subnetwork
      )
      network_ip = try(
        local.ctx.addresses[config.value.addresses.internal],
        config.value.addresses.internal,
        null
      )
      nic_type                    = config.value.nic_type
      stack_type                  = config.value.stack_type
      queue_count                 = config.value.queue_count
      internal_ipv6_prefix_length = config.value.internal_ipv6_prefix_length
      dynamic "access_config" {
        for_each = config.value.nat || config.value.network_tier != null ? [""] : []
        content {
          nat_ip = try(
            local.ctx.addresses[config.value.addresses.external],
            config.value.addresses.external,
            null
          )
          network_tier = try(config.value.network_tier, null)
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

  dynamic "network_performance_config" {
    for_each = var.network_performance_tier != null ? [""] : []
    content {
      total_egress_bandwidth_tier = var.network_performance_tier
    }
  }

  scheduling {
    automatic_restart = coalesce(
      var.scheduling_config.automatic_restart, var.scheduling_config.provisioning_model != "SPOT"
    )
    instance_termination_action = local.termination_action
    on_host_maintenance         = local.on_host_maintenance
    preemptible                 = var.scheduling_config.provisioning_model == "SPOT"
    provisioning_model          = coalesce(var.scheduling_config.provisioning_model, "STANDARD")
    min_node_cpus               = var.scheduling_config.min_node_cpus
    maintenance_interval        = var.scheduling_config.maintenance_interval

    dynamic "max_run_duration" {
      for_each = var.scheduling_config.max_run_duration == null ? [] : [""]
      content {
        nanos   = var.scheduling_config.max_run_duration.nanos
        seconds = var.scheduling_config.max_run_duration.seconds
      }
    }

    dynamic "local_ssd_recovery_timeout" {
      for_each = var.scheduling_config.local_ssd_recovery_timeout == null ? [] : [""]
      content {
        nanos   = var.scheduling_config.local_ssd_recovery_timeout.nanos
        seconds = var.scheduling_config.local_ssd_recovery_timeout.seconds
      }
    }

    dynamic "node_affinities" {
      for_each = var.scheduling_config.node_affinities
      iterator = affinity
      content {
        key      = affinity.key
        operator = affinity.value.in ? "IN" : "NOT_IN"
        values   = affinity.value.values
      }
    }

    dynamic "graceful_shutdown" {
      for_each = var.lifecycle_config.graceful_shutdown != null ? [""] : []
      content {
        enabled = var.lifecycle_config.graceful_shutdown.enabled
        dynamic "max_duration" {
          for_each = (
            var.lifecycle_config.graceful_shutdown.enabled == true &&
            var.lifecycle_config.graceful_shutdown.max_duration_secs != null
            ? [""]
            : []
          )
          content {
            seconds = var.lifecycle_config.graceful_shutdown.max_duration_secs
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
  provider                   = google-beta
  count                      = local.is_template && local.template_regional ? 1 : 0
  project                    = local.project_id
  region                     = local.region
  name_prefix                = "${var.name}-"
  description                = var.description
  tags                       = var.tags
  machine_type               = var.machine_type
  min_cpu_platform           = var.min_cpu_platform
  can_ip_forward             = var.can_ip_forward
  metadata                   = var.metadata
  metadata_startup_script    = var.metadata_startup_script
  labels                     = var.labels
  resource_manager_tags      = var.tag_bindings_immutable
  key_revocation_action_type = var.lifecycle_config.key_revocation_action_type
  resource_policies = (
    var.resource_policies == null && var.instance_schedule == null
    ? null
    : concat(
      coalesce(var.resource_policies, []),
      coalesce(local.ischedule, [])
    )
  )
  dynamic "advanced_machine_features" {
    for_each = local.advanced_mf ? [""] : []
    content {
      enable_nested_virtualization = var.machine_features_config.enable_nested_virtualization
      enable_uefi_networking       = var.machine_features_config.enable_uefi_networking
      performance_monitoring_unit  = var.machine_features_config.performance_monitoring_unit
      threads_per_core             = var.machine_features_config.threads_per_core
      turbo_mode = (
        var.machine_features_config.enable_turbo_mode == true ? "ALL_CORE_MAX" : null
      )
      visible_core_count = var.machine_features_config.visible_core_count
    }
  }

  disk {
    boot                   = true
    architecture           = var.boot_disk.architecture
    auto_delete            = var.boot_disk.auto_delete
    disk_size_gb           = var.boot_disk.initialize_params.size
    disk_type              = var.boot_disk.initialize_params.type
    source_image           = var.boot_disk.source.image
    provisioned_iops       = var.boot_disk.initialize_params.hyperdisk.provisioned_iops
    provisioned_throughput = var.boot_disk.initialize_params.hyperdisk.provisioned_throughput
    resource_manager_tags  = var.tag_bindings_immutable

    dynamic "disk_encryption_key" {
      for_each = var.encryption != null ? [""] : []
      content {
        kms_key_self_link = lookup(
          local.ctx_kms_keys,
          var.encryption.kms_key_self_link,
          var.encryption.kms_key_self_link
        )
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_compute != null ? [""] : []
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
    for_each = local.attached_disks_ordered
    iterator = disk_iter
    content {
      architecture = var.boot_disk.architecture
      auto_delete  = var.attached_disks[disk_iter.value.key].mode == "READ_ONLY" ? null : var.attached_disks[disk_iter.value.key].auto_delete
      device_name  = coalesce(var.attached_disks[disk_iter.value.key].device_name, var.attached_disks[disk_iter.value.key].name, disk_iter.value.key)
      disk_name = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? coalesce(var.attached_disks[disk_iter.value.key].name, disk_iter.value.key)
        : null
      )
      mode                  = var.attached_disks[disk_iter.value.key].mode
      resource_manager_tags = var.tag_bindings_immutable
      source_image          = var.attached_disks[disk_iter.value.key].source.image
      source                = var.attached_disks[disk_iter.value.key].source.attach
      type                  = "PERSISTENT"
      # Cannot use `source` with any of the fields in
      # [disk_size_gb disk_name disk_type source_image labels]
      disk_type = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? var.attached_disks[disk_iter.value.key].initialize_params.type
        : null
      )
      disk_size_gb = (
        var.attached_disks[disk_iter.value.key].source.attach == null
        ? var.attached_disks[disk_iter.value.key].initialize_params.size
        : null
      )
      provisioned_iops = (
        var.attached_disks[disk_iter.value.key].initialize_params.hyperdisk.provisioned_iops
      )
      provisioned_throughput = (
        var.attached_disks[disk_iter.value.key].initialize_params.hyperdisk.provisioned_throughput
      )
      dynamic "disk_encryption_key" {
        for_each = var.encryption != null ? [""] : []
        content {
          kms_key_self_link = lookup(
            local.ctx_kms_keys,
            var.encryption.kms_key_self_link,
            var.encryption.kms_key_self_link
          )
        }
      }
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    iterator = config
    content {
      network = lookup(
        local.ctx.networks, config.value.network, config.value.network
      )
      subnetwork = lookup(
        local.ctx.subnets, config.value.subnetwork, config.value.subnetwork
      )
      network_ip = try(
        local.ctx.addresses[config.value.addresses.internal],
        config.value.addresses.internal,
        null
      )
      nic_type                    = config.value.nic_type
      stack_type                  = config.value.stack_type
      queue_count                 = config.value.queue_count
      internal_ipv6_prefix_length = config.value.internal_ipv6_prefix_length
      dynamic "access_config" {
        for_each = config.value.nat || config.value.network_tier != null ? [""] : []
        content {
          nat_ip = try(
            local.ctx.addresses[config.value.addresses.external],
            config.value.addresses.external,
            null
          )
          network_tier = try(config.value.network_tier, null)
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
    automatic_restart = coalesce(
      var.scheduling_config.automatic_restart, var.scheduling_config.provisioning_model != "SPOT"
    )
    instance_termination_action = local.termination_action
    on_host_maintenance         = local.on_host_maintenance
    preemptible                 = var.scheduling_config.provisioning_model == "SPOT"
    provisioning_model          = coalesce(var.scheduling_config.provisioning_model, "STANDARD")
    min_node_cpus               = var.scheduling_config.min_node_cpus
    maintenance_interval        = var.scheduling_config.maintenance_interval

    dynamic "max_run_duration" {
      for_each = var.scheduling_config.max_run_duration == null ? [] : [""]
      content {
        nanos   = var.scheduling_config.max_run_duration.nanos
        seconds = var.scheduling_config.max_run_duration.seconds
      }
    }

    dynamic "local_ssd_recovery_timeout" {
      for_each = var.scheduling_config.local_ssd_recovery_timeout == null ? [] : [""]
      content {
        nanos   = var.scheduling_config.local_ssd_recovery_timeout.nanos
        seconds = var.scheduling_config.local_ssd_recovery_timeout.seconds
      }
    }

    dynamic "node_affinities" {
      for_each = var.scheduling_config.node_affinities
      iterator = affinity
      content {
        key      = affinity.key
        operator = affinity.value.in ? "IN" : "NOT_IN"
        values   = affinity.value.values
      }
    }

    dynamic "graceful_shutdown" {
      for_each = var.lifecycle_config.graceful_shutdown != null ? [""] : []
      content {
        enabled = var.lifecycle_config.graceful_shutdown.enabled
        dynamic "max_duration" {
          for_each = (
            var.lifecycle_config.graceful_shutdown.enabled == true &&
            var.lifecycle_config.graceful_shutdown.max_duration_secs != null
            ? [""]
            : []
          )
          content {
            seconds = var.lifecycle_config.graceful_shutdown.max_duration_secs
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

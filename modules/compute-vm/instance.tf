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

resource "google_compute_instance" "default" {
  provider                   = google-beta
  count                      = local.is_template ? 0 : 1
  project                    = local.project_id
  zone                       = local.zone
  name                       = var.name
  hostname                   = var.hostname
  description                = var.description
  tags                       = var.tags
  machine_type               = var.machine_type
  min_cpu_platform           = var.min_cpu_platform
  can_ip_forward             = var.can_ip_forward
  allow_stopping_for_update  = var.lifecycle_config.allow_stopping_for_update
  deletion_protection        = var.lifecycle_config.deletion_protection
  key_revocation_action_type = var.lifecycle_config.key_revocation_action_type
  enable_display             = var.enable_display
  labels                     = var.labels
  metadata                   = var.metadata
  metadata_startup_script    = var.metadata_startup_script
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

  dynamic "attached_disk" {
    for_each = local.attached_disks_zonal
    iterator = disk
    content {
      device_name = coalesce(
        disk.value.device_name, disk.value.name, disk.key
      )
      mode = disk.value.mode
      source = (
        disk.value.source.attach != null
        ? disk.value.source.attach
        : google_compute_disk.disks[disk.key].name
      )
    }
  }

  dynamic "attached_disk" {
    for_each = local.attached_disks_regional
    iterator = disk
    content {
      device_name = coalesce(
        disk.value.device_name, disk.value.name, disk.key
      )
      mode = disk.value.mode
      source = (
        disk.value.source.attach != null
        ? disk.value.source.attach
        : google_compute_region_disk.disks[disk.key].id
      )
    }
  }

  boot_disk {
    auto_delete = (
      var.boot_disk.use_independent_disk != null
      ? false
      : var.boot_disk.auto_delete
    )
    source = (
      var.boot_disk.use_independent_disk != null
      ? google_compute_disk.boot[0].id
      : try(coalesce(
        var.boot_disk.source.snapshot,
        var.boot_disk.source.attach
      ), null)
    )
    disk_encryption_key_raw = (
      var.encryption != null ?
      try(
        local.ctx_kms_keys[var.encryption.disk_encryption_key_raw],
        var.encryption.disk_encryption_key_raw
      )
      : null
    )
    kms_key_self_link = (
      var.encryption != null
      ? try(
        local.ctx_kms_keys[var.encryption.kms_key_self_link],
        var.encryption.kms_key_self_link
      )
      : null
    )
    dynamic "initialize_params" {
      for_each = (
        var.boot_disk.initialize_params == null
        ||
        var.boot_disk.use_independent_disk != null
        || (
          var.boot_disk.source.snapshot != null &&
          var.boot_disk.source.attach != null
        )
        ? []
        : [""]
      )
      content {
        architecture           = var.boot_disk.architecture
        image                  = var.boot_disk.source.image
        size                   = var.boot_disk.initialize_params.size
        type                   = var.boot_disk.initialize_params.type
        resource_manager_tags  = var.tag_bindings_immutable
        provisioned_iops       = var.boot_disk.initialize_params.hyperdisk.provisioned_iops
        provisioned_throughput = var.boot_disk.initialize_params.hyperdisk.provisioned_throughput
        storage_pool           = var.boot_disk.initialize_params.hyperdisk.storage_pool
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.confidential_compute != null ? [""] : []
    content {
      enable_confidential_compute = true
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

  dynamic "scratch_disk" {
    for_each = [
      for i in range(0, var.scratch_disks.count) : var.scratch_disks.interface
    ]
    iterator = config
    content {
      interface = config.value
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

  dynamic "params" {
    for_each = var.tag_bindings_immutable == null ? [] : [""]
    content {
      resource_manager_tags = var.tag_bindings_immutable
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.gpu ? [var.gpu] : []
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }
}

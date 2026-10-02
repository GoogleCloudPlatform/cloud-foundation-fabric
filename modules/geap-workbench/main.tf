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

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p = "$"
  location = (
    var.location == null
    ? null
    : lookup(local.ctx.locations, var.location, var.location)
  )
  metadata = merge(
    var.metadata,
    var.metadata_startup_script == null ? {} : {
      "startup-script" = var.metadata_startup_script
    }
  )
  name = (
    var.prefix == null
    ? var.name
    : "${var.prefix}-${var.name}"
  )
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  service_account = var.service_account == null ? null : {
    email = (
      try(var.service_account.auto_create, false)
      ? google_service_account.service_account[0].email
      : (
        var.service_account.email == null
        ? null
        : lookup(
          local.ctx.service_accounts,
          var.service_account.email,
          var.service_account.email
        )
      )
    )
    scopes = var.service_account.scopes
  }
}

resource "google_service_account" "service_account" {
  count        = try(var.service_account.auto_create, false) ? 1 : 0
  project      = local.project_id
  account_id   = "tf-wb-${var.name}"
  display_name = "Terraform Workbench ${var.name}."
}

resource "google_workbench_instance" "default" {
  provider                   = google
  project                    = local.project_id
  name                       = local.name
  location                   = local.location
  labels                     = var.labels
  instance_owners            = var.instance_owners
  disable_proxy_access       = var.disable_proxy_access
  desired_state              = var.desired_state
  enable_deletion_protection = var.enable_deletion_protection
  deletion_policy            = var.deletion_policy

  gce_setup {
    disable_public_ip    = var.disable_public_ip
    enable_ip_forwarding = var.enable_ip_forwarding
    machine_type         = var.machine_type
    metadata             = local.metadata
    min_cpu_platform     = var.min_cpu_platform
    tags                 = var.tags

    dynamic "accelerator_configs" {
      for_each = (
        var.accelerator_config != null
        ? [var.accelerator_config]
        : []
      )
      content {
        core_count = accelerator_configs.value.core_count
        type       = accelerator_configs.value.type
      }
    }

    dynamic "boot_disk" {
      for_each = var.boot_disk != null ? [var.boot_disk] : []
      content {
        disk_size_gb    = boot_disk.value.disk_size_gb
        disk_type       = boot_disk.value.disk_type
        disk_encryption = boot_disk.value.disk_encryption
        kms_key = (
          boot_disk.value.kms_key == null
          ? null
          : lookup(
            local.ctx.kms_keys,
            boot_disk.value.kms_key,
            boot_disk.value.kms_key
          )
        )
      }
    }

    dynamic "confidential_instance_config" {
      for_each = (
        var.confidential_instance_config != null
        ? [var.confidential_instance_config]
        : []
      )
      content {
        confidential_instance_type = (
          confidential_instance_config.value.confidential_instance_type
        )
      }
    }

    dynamic "container_image" {
      for_each = var.container_image != null ? [var.container_image] : []
      content {
        repository = container_image.value.repository
        tag        = container_image.value.tag
      }
    }

    dynamic "data_disks" {
      for_each = var.data_disks != null ? [var.data_disks] : []
      content {
        disk_size_gb    = data_disks.value.disk_size_gb
        disk_type       = data_disks.value.disk_type
        disk_encryption = data_disks.value.disk_encryption
        kms_key = (
          data_disks.value.kms_key == null
          ? null
          : lookup(
            local.ctx.kms_keys,
            data_disks.value.kms_key,
            data_disks.value.kms_key
          )
        )
        resource_policies = data_disks.value.resource_policies
      }
    }

    dynamic "network_interfaces" {
      for_each = var.network_interfaces
      content {
        network = (
          network_interfaces.value.network == null
          ? null
          : lookup(
            local.ctx.networks,
            network_interfaces.value.network,
            network_interfaces.value.network
          )
        )
        nic_type = network_interfaces.value.nic_type
        subnet = (
          network_interfaces.value.subnet == null
          ? null
          : lookup(
            local.ctx.subnets,
            network_interfaces.value.subnet,
            network_interfaces.value.subnet
          )
        )

        dynamic "access_configs" {
          for_each = (
            network_interfaces.value.access_configs != null
            ? network_interfaces.value.access_configs
            : []
          )
          content {
            external_ip = access_configs.value.external_ip
          }
        }
      }
    }

    dynamic "reservation_affinity" {
      for_each = (
        var.reservation_affinity != null
        ? [var.reservation_affinity]
        : []
      )
      content {
        consume_reservation_type = (
          reservation_affinity.value.consume_reservation_type
        )
        key    = reservation_affinity.value.key
        values = reservation_affinity.value.values
      }
    }

    dynamic "service_accounts" {
      for_each = local.service_account != null ? [1] : []
      content {
        email  = local.service_account.email
        scopes = local.service_account.scopes
      }
    }

    dynamic "shielded_instance_config" {
      for_each = (
        var.shielded_instance_config != null
        ? [var.shielded_instance_config]
        : []
      )
      content {
        enable_secure_boot = (
          shielded_instance_config.value.enable_secure_boot
        )
        enable_vtpm = (
          shielded_instance_config.value.enable_vtpm
        )
        enable_integrity_monitoring = (
          shielded_instance_config.value.enable_integrity_monitoring
        )
      }
    }

    dynamic "vm_image" {
      for_each = var.vm_image != null ? [var.vm_image] : []
      content {
        family  = vm_image.value.family
        name    = vm_image.value.name
        project = vm_image.value.project
      }
    }
  }
}

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
  attached_disks_regional = {
    for k, v in var.attached_disks : k => v
    if v.initialize_params.replica_zone != null
  }
  attached_disks_zonal = {
    for k, v in var.attached_disks : k => v
    if v.initialize_params.replica_zone == null
  }
}

resource "google_compute_disk" "boot" {
  count = (
    !local.is_template && var.boot_disk.use_independent_disk != null ? 1 : 0
  )
  project = local.project_id
  zone    = local.zone
  # by default, GCP creates boot disks with the same name as the instance
  # the deviation here is kept for backwards compatibility
  name = coalesce(
    var.boot_disk.use_independent_disk.name, "${var.name}-boot"
  )
  image                  = var.boot_disk.source.image
  architecture           = var.boot_disk.initialize_params.architecture
  type                   = var.boot_disk.initialize_params.type
  size                   = var.boot_disk.initialize_params.size
  provisioned_iops       = var.boot_disk.initialize_params.hyperdisk.provisioned_iops
  provisioned_throughput = var.boot_disk.initialize_params.hyperdisk.provisioned_throughput
  storage_pool           = var.boot_disk.initialize_params.hyperdisk.storage_pool
  labels = merge(var.labels, {
    disk_name = "boot"
    disk_type = var.boot_disk.initialize_params.type
  })
  dynamic "disk_encryption_key" {
    for_each = var.encryption != null ? [""] : []
    content {
      raw_key = var.encryption.disk_encryption_key_raw
      kms_key_self_link = lookup(
        local.ctx_kms_keys,
        var.encryption.kms_key_self_link,
        var.encryption.kms_key_self_link
      )
    }
  }
}

resource "google_compute_disk" "disks" {
  for_each = local.is_template ? {} : {
    for k, v in local.attached_disks_zonal :
    k => v if v.source.attach == null
  }
  project                = local.project_id
  zone                   = local.zone
  name                   = coalesce(each.value.name, "${var.name}-${each.key}")
  type                   = each.value.initialize_params.type
  size                   = each.value.initialize_params.size
  architecture           = each.value.initialize_params.architecture
  image                  = each.value.source.image
  provisioned_iops       = each.value.initialize_params.hyperdisk.provisioned_iops
  provisioned_throughput = each.value.initialize_params.hyperdisk.provisioned_throughput
  snapshot               = each.value.source.snapshot
  storage_pool           = each.value.initialize_params.hyperdisk.storage_pool
  labels = merge(var.labels, {
    disk_name = coalesce(each.value.name, each.key)
    disk_type = each.value.initialize_params.type
  })
  dynamic "disk_encryption_key" {
    for_each = var.encryption != null ? [""] : []
    content {
      raw_key = var.encryption.disk_encryption_key_raw
      kms_key_self_link = lookup(
        local.ctx_kms_keys,
        var.encryption.kms_key_self_link,
        var.encryption.kms_key_self_link
      )
    }
  }
}

resource "google_compute_region_disk" "disks" {
  for_each = local.is_template ? {} : {
    for k, v in local.attached_disks_regional :
    k => v if v.source.attach == null
  }
  project       = local.project_id
  region        = local.region
  replica_zones = [local.zone, each.value.initialize_params.replica_zone]
  name          = coalesce(each.value.name, "${var.name}-${each.key}")
  type          = each.value.initialize_params.type
  size          = each.value.initialize_params.size
  # image                  = each.value.source.image
  snapshot = each.value.source.snapshot
  labels = merge(var.labels, {
    disk_name = coalesce(each.value.name, each.key)
    disk_type = each.value.initialize_params.type
  })
  dynamic "disk_encryption_key" {
    for_each = var.encryption != null ? [""] : []
    content {
      raw_key = var.encryption.disk_encryption_key_raw
      # TODO: check if self link works here
      kms_key_name = lookup(
        local.ctx_kms_keys,
        var.encryption.kms_key_self_link,
        var.encryption.kms_key_self_link
      )

    }
  }
}


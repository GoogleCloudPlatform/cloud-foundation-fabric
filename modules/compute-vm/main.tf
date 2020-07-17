/**
 * Copyright 2019 Google LLC
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
  attached_disks = {
    for disk in var.attached_disks :
    disk.name => merge(disk, {
      options = disk.options == null ? var.attached_disk_defaults : disk.options
    })
  }
  attached_disks_pairs = {
    for pair in setproduct(keys(local.names), keys(local.attached_disks)) :
    "${pair[0]}-${pair[1]}" => { disk_name = pair[1], name = pair[0] }
  }
  iam_roles = var.use_instance_template ? {} : {
    for pair in setproduct(var.iam_roles, keys(local.names)) :
    "${pair.0}/${pair.1}" => { role = pair.0, name = pair.1 }
  }
  names = (
    var.use_instance_template ? { "${var.name}" = 0 } : {
      for i in range(0, var.instance_count) : "${var.name}-${i + 1}" => i
    }
  )
  service_account_email = (
    var.service_account_create
    ? (
      length(google_service_account.service_account) > 0
      ? google_service_account.service_account[0].email
      : null
    )
    : var.service_account
  )
  service_account_scopes = (
    length(var.service_account_scopes) > 0
    ? var.service_account_scopes
    : (
      var.service_account_create
      ? ["https://www.googleapis.com/auth/cloud-platform"]
      : [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring.write"
      ]
    )
  )
  zones_list = length(var.zones) == 0 ? ["${var.region}-b"] : var.zones
  zones = {
    for name, i in local.names : name => element(local.zones_list, i)
  }
}

resource "google_compute_disk" "disks" {
  for_each = var.use_instance_template ? {} : local.attached_disks_pairs
  project  = var.project_id
  zone     = local.zones[each.value.name]
  name     = each.key
  type     = local.attached_disks[each.value.disk_name].options.type
  size     = local.attached_disks[each.value.disk_name].size
  labels = merge(var.labels, {
    disk_name = local.attached_disks[each.value.disk_name].name
    disk_type = local.attached_disks[each.value.disk_name].options.type
    image     = local.attached_disks[each.value.disk_name].image
  })
  dynamic disk_encryption_key {
    for_each = var.encryption != null ? [""] : []

    content {
      raw_key           = var.encryption.disk_encryption_key_raw
      kms_key_self_link = var.encryption.kms_key_self_link
    }
  }
}

resource "google_compute_instance" "default" {
  for_each                  = var.use_instance_template ? {} : local.names
  project                   = var.project_id
  zone                      = local.zones[each.key]
  name                      = each.key
  hostname                  = var.hostname
  description               = "Managed by the compute-vm Terraform module."
  tags                      = var.tags
  machine_type              = var.instance_type
  min_cpu_platform          = var.min_cpu_platform
  can_ip_forward            = var.options.can_ip_forward
  allow_stopping_for_update = var.options.allow_stopping_for_update
  deletion_protection       = var.options.deletion_protection
  metadata                  = var.metadata
  labels                    = var.labels

  dynamic attached_disk {
    for_each = {
      for resource_name, pair in local.attached_disks_pairs :
      resource_name => local.attached_disks[pair.disk_name] if pair.name == each.key
    }
    iterator = config
    content {
      device_name = config.value.name
      mode        = config.value.options.mode
      source      = google_compute_disk.disks[config.key].name
    }
  }

  boot_disk {
    initialize_params {
      type  = var.boot_disk.type
      image = var.boot_disk.image
      size  = var.boot_disk.size
    }
    disk_encryption_key_raw = var.encryption != null ? var.encryption.disk_encryption_key_raw : null
    kms_key_self_link       = var.encryption != null ? var.encryption.kms_key_self_link : null
  }

  dynamic network_interface {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      network_ip = config.value.addresses == null ? null : (
        length(config.value.addresses.internal) == 0
        ? null
        : config.value.addresses.internal[each.value]
      )
      dynamic access_config {
        for_each = config.value.nat ? [config.value.addresses] : []
        iterator = addresses
        content {
          nat_ip = addresses.value == null ? null : (
            length(addresses.value.external) == 0 ? null : addresses.value.external[each.value]
          )
        }
      }
    }
  }

  scheduling {
    automatic_restart   = ! var.options.preemptible
    on_host_maintenance = var.options.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible         = var.options.preemptible
  }

  dynamic scratch_disk {
    for_each = [
      for i in range(0, var.scratch_disks.count) : var.scratch_disks.interface
    ]
    iterator = config
    content {
      interface = config.value
    }
  }

  service_account {
    email  = local.service_account_email
    scopes = local.service_account_scopes
  }

  dynamic shielded_instance_config {
    for_each = var.shielded_config != null ? [var.shielded_config] : []
    iterator = config
    content {
      enable_secure_boot          = config.value.enable_secure_boot
      enable_vtpm                 = config.value.enable_vtpm
      enable_integrity_monitoring = config.value.enable_integrity_monitoring
    }
  }

  # guest_accelerator
}

resource "google_compute_instance_iam_binding" "default" {
  for_each      = local.iam_roles
  project       = var.project_id
  zone          = local.zones[each.value.name]
  instance_name = each.value.name
  role          = each.value.role
  members       = lookup(var.iam_members, each.value.role, [])
  depends_on    = [google_compute_instance.default]
}

resource "google_compute_instance_template" "default" {
  count            = var.use_instance_template ? 1 : 0
  project          = var.project_id
  region           = var.region
  name_prefix      = "${var.name}-"
  description      = "Managed by the compute-vm Terraform module."
  tags             = var.tags
  machine_type     = var.instance_type
  min_cpu_platform = var.min_cpu_platform
  can_ip_forward   = var.options.can_ip_forward
  metadata         = var.metadata
  labels           = var.labels

  disk {
    source_image = var.boot_disk.image
    disk_type    = var.boot_disk.type
    disk_size_gb = var.boot_disk.size
    boot         = true
  }

  dynamic disk {
    for_each = local.attached_disks
    iterator = config
    content {
      auto_delete  = config.value.options.auto_delete
      device_name  = config.value.name
      disk_type    = config.value.options.type
      disk_size_gb = config.value.size
      mode         = config.value.options.mode
      source_image = config.value.image
      source       = config.value.options.source
      type         = "PERSISTENT"
    }
  }

  dynamic network_interface {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      dynamic access_config {
        for_each = config.value.nat ? [""] : []
        content {}
      }
    }
  }

  scheduling {
    automatic_restart   = ! var.options.preemptible
    on_host_maintenance = var.options.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible         = var.options.preemptible
  }

  service_account {
    email  = local.service_account_email
    scopes = local.service_account_scopes
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group" "unmanaged" {
  count = (
    var.group != null && ! var.use_instance_template ? 1 : 0
  )
  project = var.project_id
  network = (
    length(var.network_interfaces) > 0
    ? var.network_interfaces.0.network
    : ""
  )
  zone        = local.zones_list[0]
  name        = var.name
  description = "Terraform-managed."
  instances = [
    for name, instance in google_compute_instance.default : instance.self_link
  ]
  dynamic named_port {
    for_each = var.group.named_ports != null ? var.group.named_ports : {}
    iterator = config
    content {
      name = config.key
      port = config.value
    }
  }
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-vm-${var.name}"
  display_name = "Terraform VM ${var.name}."
}

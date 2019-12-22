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
  addresses = (
    length(var.addresses) > 0 && ! var.use_instance_template
    ? { for name, i in local.names : name => var.addresses[i] }
    : {}
  )
  disks = {
    for pair in setproduct(values(local.names), values(var.attached_disks)) :
    "${pair[0]}-${pair[1]}" => { name = pair[0], disk_name = pair[1] }
  }
  names = (
    var.use_instance_template
    ? { "${var.name}" = 0 }
    : { for i in range(0, var.instance_count) : "${var.name}-${i + 1}" => i }
  )
  service_account = (
    var.service_account == ""
    ? google_service_account.service_account[0].email
    : var.service_account
  )
}

data "template_file" "cloud_config" {
  for_each = local.names
  template = file(var.cloud_config_path)
  vars = merge(var.cloud_config_vars, {
    address        = lookup(local.addresses, each.key, "")
    attached_disks = join(",", keys(var.attached_disks))
    id             = each.value
    name           = each.key
  })
}

resource "google_compute_disk" "disks" {
  for_each = local.disks
  project  = var.project_id
  zone     = var.zone
  name     = "${each.value.name}-${each.value.disk_name}"
  type     = var.attached_disks[each.value.disk_name].type
  size     = var.attached_disks[each.value.disk_name].size
  # TODO(ludoo): labels
}

resource "google_compute_instance" "default" {
  for_each                  = var.use_instance_template ? {} : local.names
  project                   = var.project_id
  zone                      = var.zone
  name                      = each.key
  description               = "Managed by the cos-workload Terraform module."
  tags                      = var.tags
  machine_type              = var.instance_type
  can_ip_forward            = var.options.can_ip_forward
  allow_stopping_for_update = var.options.allow_stopping_for_update

  dynamic attached_disk {
    for_each = {
      for k, v in values(local.disks) :
      k => v.disk_name if v.name == each.key
    }
    iterator = config
    content {
      source      = google_compute_disk.disks[config.key].name
      device_name = config.value
    }
  }

  boot_disk {
    initialize_params {
      type  = var.boot_disk.type
      image = var.boot_disk.image
      size  = var.boot_disk.size
    }
  }

  metadata = {
    user-data                 = data.template_file.cloud_config[each.key].rendered
    google-logging-enabled    = var.stackdriver.enable_logging ? true : null
    google-monitoring-enabled = var.stackdriver.enable_monitoring ? true : null
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    network_ip = lookup(local.addresses, each.key, null)
    dynamic access_config {
      for_each = var.nat.enabled ? [var.nat.addresses] : []
      iterator = config
      content {
        nat_ip = length(config.value) > 0 ? config.value[each.value] : null
      }
    }
  }

  scheduling {
    automatic_restart   = var.options.automatic_restart
    on_host_maintenance = var.options.on_host_maintenance
  }

  service_account {
    email  = local.service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

}

resource "google_compute_instance_template" "default" {
  count          = var.use_instance_template ? 1 : 0
  project        = var.project_id
  region         = var.region
  name_prefix    = "${var.name}-"
  description    = "Managed by the cos-workload Terraform module."
  tags           = var.tags
  machine_type   = var.instance_type
  can_ip_forward = var.options.can_ip_forward

  disk {
    source_image = var.boot_disk.image
    disk_type    = var.boot_disk.type
    disk_size_gb = var.boot_disk.size
    boot         = true
  }

  metadata = {
    user-data                 = data.template_file.cloud_config[var.name].rendered
    google-logging-enabled    = var.stackdriver.enable_logging
    google-monitoring-enabled = var.stackdriver.enable_monitoring
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    dynamic access_config {
      for_each = var.nat.enabled ? [null] : []
      content {}
    }
  }

  service_account {
    email  = local.service_account
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_service_account" "service_account" {
  count        = var.service_account == "" ? 1 : 0
  project      = var.project_id
  account_id   = "tf-vm-cos-${var.name}"
  display_name = "COS ${var.name}."
}

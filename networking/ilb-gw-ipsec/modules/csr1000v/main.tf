/**
 * Copyright 2020 Google LLC
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
  config = (
    var.config == null ? {} : {
      startup-script = "Section: IOS configuration\n${var.config}"
    }
  )
}

resource "google_compute_instance" "default" {
  project                   = var.project_id
  zone                      = var.zone
  name                      = var.name
  hostname                  = var.hostname
  description               = "Managed by the compute-vm Terraform module."
  tags                      = var.tags
  machine_type              = var.instance_type
  can_ip_forward            = true
  allow_stopping_for_update = var.options.allow_stopping_for_update
  deletion_protection       = var.options.deletion_protection
  metadata = merge(
    var.metadata, { ssh-keys = "admin:${var.ssh_key}" }, local.config
  )
  labels = var.labels

  boot_disk {
    initialize_params {
      type  = "pd-ssd"
      image = var.image
      size  = 10
    }
  }

  dynamic network_interface {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      network_ip = config.value.address
      dynamic alias_ip_range {
        for_each = config.value.alias == null ? [] : [""]
        content {
          ip_cidr_range         = config.value.alias.ip_cidr_range
          subnetwork_range_name = config.value.alias.range_name
        }
      }
    }
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  service_account {
    email  = var.service_account
    scopes = var.service_account_scopes
  }
}

resource "google_compute_instance_iam_binding" "default" {
  for_each      = toset(var.iam_roles)
  project       = var.project_id
  zone          = var.zone
  instance_name = each.value.name
  role          = each.value.role
  members       = lookup(var.iam_members, each.value.role, [])
}

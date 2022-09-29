/**
 * Copyright 2022 Google LLC
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
  interfaces = [
    for index, interface in var.network_interfaces : {
      name   = "eth${index}"
      number = index
      routes = interface.routes
    }
  ]
}

resource "google_service_account" "default" {
  project      = var.project_id
  account_id   = "simple-nva-${var.name}"
  display_name = "Managed by the Simple-NVA Terraform module."
}

resource "google_compute_instance" "default" {
  project        = var.project_id
  name           = var.name
  description    = "Managed by the Simple-NVA Terraform module."
  can_ip_forward = true
  machine_type   = var.instance_type
  tags           = var.tags
  zone           = var.zone
  metadata = {
    user-data = templatefile("${path.module}/assets/cloud-config.yaml", {
      interfaces           = local.interfaces
      enable_health_checks = var.enable_health_checks
    })
  }

  boot_disk {
    initialize_params {
      type  = "pd-ssd"
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size  = 10
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    iterator = config
    content {
      network    = config.value.network
      subnetwork = config.value.subnetwork
      network_ip = try(config.value.addresses.internal, null)
    }
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

}

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
  cloud_config = templatefile(
    "${path.module}/cloud-config.yaml", var.gitlab_config
  )
  vm_roles = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
  zones    = { for z in var.zones : z => "${var.region}-${z}" }
}

resource "google_service_account" "default" {
  project      = var.project_id
  account_id   = "${var.prefix}-gitlab"
  display_name = "Gitlab VM service account."
}

resource "google_project_iam_member" "default" {
  for_each = toset(local.vm_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.default.email}"
}

resource "google_compute_health_check" "http" {
  provider = google-beta
  project  = var.project_id
  name     = "${var.prefix}-http"
  http_health_check {
    request_path = "/"
  }
  log_config {
    enable = true
  }
}

resource "google_compute_health_check" "ssh" {
  provider = google-beta
  project  = var.project_id
  name     = "${var.prefix}-ssh"
  tcp_health_check {
    port = 22
  }
  log_config {
    enable = true
  }
}

resource "google_compute_region_disk" "data" {
  project       = var.project_id
  name          = "${var.prefix}-data"
  type          = "pd-balanced"
  region        = var.region
  replica_zones = values(local.zones)
  size          = var.gce_config.disk_size
}

resource "google_compute_instance_template" "default" {
  project      = var.project_id
  name_prefix  = "${var.prefix}-"
  machine_type = var.gce_config.machine_type

  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete  = true
    boot         = true
    device_name  = "boot"
    disk_type    = "pd-balanced"
  }
  disk {
    source      = google_compute_region_disk.data.self_link
    auto_delete = false
    boot        = false
    device_name = "data"
  }
  metadata = {
    user-data = local.cloud_config
  }
  network_interface {
    subnetwork = var.subnet_self_link
  }
  service_account {
    email = google_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email",
    ]
  }
  tags = ["http-server", "ssh", var.prefix]
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "default" {
  provider           = google-beta
  for_each           = local.zones
  project            = var.project_id
  zone               = each.value
  name               = "${var.prefix}-${each.key}"
  base_instance_name = var.prefix
  target_size        = null
  auto_healing_policies {
    health_check      = google_compute_health_check.ssh.self_link
    initial_delay_sec = 60
  }
  named_port {
    name = "http"
    port = 80
  }
  named_port {
    name = "https"
    port = 443
  }
  update_policy {
    max_surge_fixed       = 0
    max_unavailable_fixed = 1
    minimal_action        = "RESTART"
    replacement_method    = "RECREATE"
    type                  = "OPPORTUNISTIC"
  }
  version {
    instance_template = google_compute_instance_template.default.self_link
    name              = "default"
  }
}

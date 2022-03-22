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
  dns_enabled = var.gitlab_config.hostname != null
  network_project_id = regex(
    "^.*?projects/([^/]+)/.*?$", var.network_config.vpc_self_link
  )[0]
  vm_roles = ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
  zones    = { for z in var.gce_config.zones : z => "${var.region}-${z}" }
}

module "cloud-config" {
  source   = "../../../modules/cloud-config-container/gitlab-ce"
  env      = var.gitlab_config.env
  hostname = var.gitlab_config.hostname
  image    = var.gitlab_config.image
  mounts = {
    config = { device_name = "data", fs_path = "config" }
    data   = { device_name = "data", fs_path = "data" }
    logs   = { device_name = "data", fs_path = "logs" }
  }
}

resource "google_project_iam_member" "default" {
  for_each = toset(local.vm_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.default.email}"
}

resource "google_dns_managed_zone" "default" {
  for_each = local.dns_enabled && var.dns_config.create_zone ? { 1 = 1 } : {}
  provider = google-beta
  project  = local.network_project_id
  name     = coalesce(var.dns_config.zone_name, var.prefix)
  dns_name = join("", [
    regex("^[^\\.]+\\.(.*?)$", var.gitlab_config.hostname)[0],
    "."
  ])
  description = "Gitlab zone."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_config.vpc_self_link
    }
  }
}

resource "google_dns_record_set" "default" {
  for_each = local.dns_enabled ? { 1 = 1 } : {}
  project  = local.network_project_id
  managed_zone = (
    var.dns_config.create_zone
    ? google_dns_managed_zone.default["1"].name
    : var.dns_config.zone_name
  )
  name = "${var.gitlab_config.hostname}."
  type = "A"
  ttl  = 300
  rrdatas = [
    google_compute_forwarding_rule.ilb.ip_address
  ]
}

/**
 * Copyright 2021 Google LLC
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
  machine_images_files = flatten(
    [
      for config_path in var.config_directories :
      concat(
        [
          for config_file in fileset("${path.root}/${config_path}", "**/*.yaml") :
          "${path.root}/${config_path}/${config_file}"
        ]
      )

    ]
  )

  machine_images = merge(
    [
      for config_file in local.machine_images_files :
      try(yamldecode(file(config_file)), {})
    ]...
  )
}

resource "google_compute_instance_from_machine_image" "compute-vm-from-image" {
  provider             = google-beta
  for_each             = local.machine_images
  project              = var.project_id
  name                 = each.value.name
  source_machine_image = each.value.source_machine_image
  zone                 = try(each.value.zone, null)
  network_interface {
    network            = try(each.value.network, null)
    subnetwork         = try(each.value.subnetwork, null)
    subnetwork_project = try(each.value.subnetwork_project, null)
  }
  can_ip_forward            = try(each.value.can_ip_forward, "false")
  labels                    = try(each.value.labels, null)
  metadata                  = tomap(try(each.value.metadata, null))
  machine_type              = try(each.value.machine_type, null)
  allow_stopping_for_update = try(each.value.allow_stopping_for_update, null)
  description               = try(each.value.description, null)
  deletion_protection       = try(each.value.deletion_protection, null)
  hostname                  = try(each.value.hostname, null)
  guest_accelerator         = try(each.value.guest_accelerator, null)
  metadata_startup_script   = try(each.value.metadata_startup_script, null)
  min_cpu_platform          = try(each.value.min_cpu_platform, null)
}

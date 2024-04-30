/**
 * Copyright 2023 Google LLC
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
  workstations = merge(flatten([for k1, v1 in var.workstation_configs :
    { for k2, v2 in v1.workstations :
      "${k1}-${k2}" => merge({
        workstation_config_id = k1
        workstation_id        = k2
  }, v2) }])...)
}

resource "google_workstations_workstation_cluster" "cluster" {
  provider               = google-beta
  workstation_cluster_id = var.id
  project                = var.project_id
  display_name           = var.display_name
  network                = var.network_config.network
  subnetwork             = var.network_config.subnetwork
  location               = var.location
  annotations            = var.annotations
  labels                 = var.labels
  dynamic "private_cluster_config" {
    for_each = var.private_cluster_config == null ? [] : [""]
    content {
      enable_private_endpoint = var.private_cluster_config.enable_private_endpoint
      allowed_projects        = var.private_cluster_config.allowed_projects
    }
  }
  dynamic "domain_config" {
    for_each = var.domain == null ? [] : [""]
    content {
      domain = var.domain
    }
  }
}

resource "google_workstations_workstation_config" "configs" {
  for_each               = var.workstation_configs
  provider               = google-beta
  project                = google_workstations_workstation_cluster.cluster.project
  workstation_config_id  = each.key
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = google_workstations_workstation_cluster.cluster.location
  idle_timeout           = each.value.idle_timeout
  running_timeout        = each.value.running_timeout
  replica_zones          = each.value.replica_zones
  annotations            = each.value.annotations
  labels                 = each.value.labels
  dynamic "host" {
    for_each = each.value.gce_instance == null ? [] : [""]
    content {
      gce_instance {
        machine_type                 = each.value.gce_instance.machine_type
        service_account              = each.value.gce_instance.service_account
        service_account_scopes       = each.value.gce_instance.service_account_scopes
        pool_size                    = each.value.gce_instance.pool_size
        boot_disk_size_gb            = each.value.gce_instance.boot_disk_size_gb
        tags                         = each.value.gce_instance.tags
        disable_public_ip_addresses  = each.value.gce_instance.disable_public_ip_addresses
        enable_nested_virtualization = each.value.gce_instance.enable_nested_virtualization
        dynamic "shielded_instance_config" {
          for_each = each.value.gce_instance.shielded_instance_config == null ? [] : [""]
          content {
            enable_secure_boot          = each.value.gce_instance.shielded_instance_config.enable_secure_boot
            enable_vtpm                 = each.value.gce_instance.shielded_instance_config.enable_vtpm
            enable_integrity_monitoring = each.value.gce_instance.shielded_instance_config.enable_integrity_monitoring
          }
        }
        dynamic "confidential_instance_config" {
          for_each = each.value.gce_instance.enable_confidential_compute ? [""] : []
          content {
            enable_confidential_compute = true
          }
        }
        dynamic "accelerators" {
          for_each = each.value.gce_instance.accelerators
          content {
            type  = accelerators.value.type
            count = accelerators.value.count
          }
        }
      }
    }
  }
  dynamic "container" {
    for_each = each.value.container == null ? [] : [""]
    content {
      image       = each.value.container.image
      command     = each.value.container.command
      args        = each.value.container.args
      working_dir = each.value.container.working_dir
      env         = each.value.container.env
      run_as_user = each.value.container.run_as_user
    }
  }
  dynamic "encryption_key" {
    for_each = each.value.encryption_key == null ? [] : [""]
    content {
      kms_key                 = each.value.encryption_key.kms_key
      kms_key_service_account = each.value.encryption_key.kms_key_service_account
    }
  }
  dynamic "persistent_directories" {
    for_each = each.value.persistent_directories
    content {
      mount_path = persistent_directories.value.mount_path
      dynamic "gce_pd" {
        for_each = persistent_directories.value.gce_pd == null ? [] : [""]
        content {
          size_gb        = persistent_directories.value.gce_pd.size_gb
          fs_type        = persistent_directories.value.gce_pd.fs_type
          disk_type      = persistent_directories.value.gce_pd.disk_type
          reclaim_policy = persistent_directories.value.gce_pd.reclaim_policy
        }
      }
    }
  }
}

resource "google_workstations_workstation" "workstations" {
  provider               = google-beta
  for_each               = local.workstations
  project                = google_workstations_workstation_cluster.cluster.project
  workstation_id         = each.value.workstation_id
  workstation_config_id  = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.cluster.workstation_cluster_id
  location               = google_workstations_workstation_cluster.cluster.location
  labels                 = each.value.labels
  env                    = each.value.env
  annotations            = each.value.annotations
}


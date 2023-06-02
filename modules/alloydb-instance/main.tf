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
  quantity_based_retention_count = (
    var.automated_backup_policy != null ? (var.automated_backup_policy.quantity_based_retention_count != null ? [var.automated_backup_policy.quantity_based_retention_count] : []) : []
  )
  read_pool_instance = (
    var.read_pool_instance != null ?
    { for read_pool_instances in var.read_pool_instance : read_pool_instances.instance_id => read_pool_instances } : {}
  )
  time_based_retention_count = (
    var.automated_backup_policy != null ? (var.automated_backup_policy.time_based_retention_count != null ? [var.automated_backup_policy.time_based_retention_count] : []) : []
  )
}

resource "google_alloydb_cluster" "default" {
  cluster_id   = var.cluster_id
  location     = var.location
  network      = var.network_self_link
  display_name = var.display_name
  project      = var.project_id
  labels       = var.labels

  dynamic "automated_backup_policy" {
    for_each = var.automated_backup_policy == null ? [] : [""]
    content {
      location      = var.automated_backup_policy.location
      backup_window = var.automated_backup_policy.backup_window
      enabled       = var.automated_backup_policy.enabled
      labels        = var.automated_backup_policy.labels


      weekly_schedule {
        days_of_week = automated_backup_policy.value.weekly_schedule.days_of_week
        dynamic "start_times" {
          for_each = { for i, time in automated_backup_policy.value.weekly_schedule.start_times : i => {
            hours   = tonumber(split(":", time)[0])
            minutes = tonumber(split(":", time)[1])
            seconds = tonumber(split(":", time)[2])
            nanos   = tonumber(split(":", time)[3])
            }
          }
          content {
            hours   = start_times.value.hours
            minutes = start_times.value.minutes
            seconds = start_times.value.seconds
            nanos   = start_times.value.nanos
          }
        }
      }

      dynamic "quantity_based_retention" {
        for_each = local.quantity_based_retention_count
        content {
          count = quantity_based_retention.value
        }
      }

      dynamic "time_based_retention" {
        for_each = local.time_based_retention_count
        content {
          retention_period = time_based_retention.value
        }
      }

      dynamic "encryption_config" {
        for_each = automated_backup_policy.value.backup_encryption_key_name == null ? [] : ["encryption_config"]
        content {
          kms_key_name = automated_backup_policy.value.backup_encryption_key_name
        }
      }

    }

  }

  dynamic "initial_user" {
    for_each = var.initial_user == null ? [] : ["initial_user"]
    content {
      user     = var.initial_user.user
      password = var.initial_user.password
    }
  }

  dynamic "encryption_config" {
    for_each = var.encryption_key_name == null ? [] : ["encryption_config"]
    content {
      kms_key_name = var.encryption_key_name
    }
  }
}

resource "google_alloydb_instance" "primary" {
  cluster           = google_alloydb_cluster.default.name
  instance_id       = var.primary_instance_config.instance_id
  instance_type     = "PRIMARY"
  display_name      = var.primary_instance_config.display_name
  database_flags    = var.primary_instance_config.database_flags
  labels            = var.primary_instance_config.labels
  annotations       = var.primary_instance_config.annotations
  gce_zone          = var.primary_instance_config.availability_type == "ZONAL" ? var.primary_instance_config.gce_zone : null
  availability_type = var.primary_instance_config.availability_type

  machine_config {
    cpu_count = var.primary_instance_config.machine_cpu_count
  }

}

resource "google_alloydb_instance" "read_pool" {
  for_each          = local.read_pool_instance
  cluster           = google_alloydb_cluster.default.name
  instance_id       = each.key
  instance_type     = "READ_POOL"
  availability_type = each.value.availability_type
  gce_zone          = each.value.availability_type == "ZONAL" ? each.value.availability_type.gce_zone : null

  read_pool_config {
    node_count = each.value.node_count
  }

  database_flags = each.value.database_flags
  machine_config {
    cpu_count = each.value.machine_cpu_count
  }

  depends_on = [google_alloydb_instance.primary, google_compute_network.default, google_compute_global_address.private_ip_alloc, google_service_networking_connection.vpc_connection]
}

resource "google_compute_network" "default" {
  name = var.network_name
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "adb-all"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = google_compute_network.default.id
}

resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

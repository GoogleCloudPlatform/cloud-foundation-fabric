/**
 * Copyright 2024 Google LLC
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
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  # has_replicas = try(length(var.replicas) > 0, false)
  is_regional = var.availability_type == "REGIONAL" ? true : false
  # secondary instance type is aligned with cluster type unless apply is targeting a promotion, in that
  # case cluster will be 'primary' while instance still 'secondary'.
  secondary_instance_type = try(var.cross_region_replication.promote_secondary && google_alloydb_cluster.secondary[0].cluster_type == "SECONDARY" ? "SECONDARY" : google_alloydb_cluster.secondary[0].cluster_type, null)

  users = {
    for k, v in coalesce(var.users, {}) :
    k => {
      name     = k
      password = try(v.type, "ALLOYDB_BUILT_IN") == "ALLOYDB_BUILT_IN" ? try(random_password.passwords[k].result, v.password) : null
      roles    = v.roles
      type     = coalesce(v.type, "ALLOYDB_BUILT_IN")
    }
  }
}

resource "google_alloydb_cluster" "primary" {
  project          = var.project_id
  cluster_id       = "${local.prefix}${var.cluster_name}"
  database_version = var.database_version
  deletion_policy  = var.deletion_policy
  labels           = var.labels
  location         = var.location

  network_config {
    network            = var.network_config.network
    allocated_ip_range = var.network_config.allocated_ip_range
  }

  dynamic "automated_backup_policy" {
    for_each = var.automated_backup_configuration.enabled ? { 1 = 1 } : {}
    content {
      enabled       = true
      location      = try(var.automated_backup_configuration.location, var.location)
      backup_window = var.automated_backup_configuration.backup_window
      labels        = var.labels

      dynamic "encryption_config" {
        for_each = var.encryption_config != null ? { 1 = 1 } : {}
        content {
          kms_key_name = var.encryption_config.primary_kms_key_name
        }
      }

      weekly_schedule {
        days_of_week = var.automated_backup_configuration.weekly_schedule.days_of_week
        start_times {
          hours   = var.automated_backup_configuration.weekly_schedule.start_times.hours
          minutes = var.automated_backup_configuration.weekly_schedule.start_times.minutes
          seconds = var.automated_backup_configuration.weekly_schedule.start_times.seconds
          nanos   = var.automated_backup_configuration.weekly_schedule.start_times.nanos
        }
      }

      dynamic "quantity_based_retention" {
        for_each = var.automated_backup_configuration.retention_count != null ? { 1 = 1 } : {}
        content {
          count = var.automated_backup_configuration.retention_count
        }
      }

      dynamic "time_based_retention" {
        for_each = var.automated_backup_configuration.retention_period != null ? { 1 = 1 } : {}
        content {
          retention_period = var.automated_backup_configuration.retention_period
        }
      }
    }
  }

  dynamic "continuous_backup_config" {
    for_each = var.continuous_backup_configuration.enabled ? { 1 = 1 } : {}
    content {
      enabled              = true
      recovery_window_days = var.continuous_backup_configuration.recovery_window_days
      dynamic "encryption_config" {
        for_each = var.encryption_config != null ? { 1 = 1 } : {}
        content {
          kms_key_name = var.encryption_config.primary_kms_key_name
        }
      }
    }
  }

  dynamic "encryption_config" {
    for_each = var.encryption_config != null ? { 1 = 1 } : {}
    content {
      kms_key_name = var.encryption_config.primary_kms_key_name
    }
  }

  dynamic "initial_user" {
    for_each = var.initial_user != null ? { 1 = 1 } : {}
    content {
      user     = var.initial_user.user
      password = var.initial_user.password
    }
  }

  dynamic "maintenance_update_policy" {
    for_each = var.maintenance_config.enabled ? { 1 = 1 } : {}
    content {
      maintenance_windows {
        day = var.maintenance_config.day
        start_time {
          hours   = var.maintenance_config.start_times.hours
          minutes = var.maintenance_config.start_times.minutes
          seconds = var.maintenance_config.start_times.seconds
          nanos   = var.maintenance_config.start_times.nanos
        }
      }
    }
  }
}

resource "google_alloydb_instance" "primary" {
  cluster           = google_alloydb_cluster.primary.id
  availability_type = var.availability_type
  database_flags    = var.flags
  display_name      = "${local.prefix}${var.name}"
  instance_id       = "${local.prefix}${var.name}"
  instance_type     = "PRIMARY"
  gce_zone          = local.is_regional ? null : var.gce_zone
  labels            = var.labels

  dynamic "client_connection_config" {
    for_each = var.client_connection_config != null ? { 1 = 1 } : {}
    content {
      require_connectors = var.client_connection_config.require_connectors
      dynamic "ssl_config" {
        for_each = var.client_connection_config.ssl_config != null ? { 1 = 1 } : {}
        content {
          ssl_mode = var.client_connection_config.ssl_config.ssl_mode
        }
      }
    }
  }

  dynamic "machine_config" {
    for_each = var.machine_config != null ? { 1 = 1 } : {}
    content {
      cpu_count = var.machine_config.cpu_count
    }
  }

  dynamic "network_config" {
    for_each = var.network_config != null ? { 1 = 1 } : {}
    content {
      dynamic "authorized_external_networks" {
        for_each = coalesce(var.network_config.authorized_external_networks, [])
        content {
          cidr_range = authorized_external_networks.value
        }
      }
      enable_public_ip = var.network_config.enable_public_ip
    }
  }

  dynamic "query_insights_config" {
    for_each = var.query_insights_config != null ? { 1 = 1 } : {}
    content {
      query_string_length     = var.query_insights_config.query_string_length
      record_application_tags = var.query_insights_config.record_application_tags
      record_client_address   = var.query_insights_config.record_client_address
      query_plans_per_minute  = var.query_insights_config.query_plans_per_minute
    }
  }
}

resource "google_alloydb_cluster" "secondary" {
  count            = var.cross_region_replication.enabled ? 1 : 0
  project          = var.project_id
  cluster_id       = "${local.prefix}${var.cluster_name}-secondary"
  cluster_type     = var.cross_region_replication.promote_secondary ? "PRIMARY" : "SECONDARY"
  database_version = var.database_version
  deletion_policy  = "FORCE"
  labels           = var.labels
  location         = var.cross_region_replication.region

  network_config {
    network            = var.network_config.network
    allocated_ip_range = var.network_config.allocated_ip_range
  }

  dynamic "automated_backup_policy" {
    for_each = var.automated_backup_configuration.enabled ? { 1 = 1 } : {}
    content {
      enabled       = true
      location      = var.cross_region_replication.region
      backup_window = var.automated_backup_configuration.backup_window
      labels        = var.labels

      dynamic "encryption_config" {
        for_each = var.encryption_config != null ? { 1 = 1 } : {}
        content {
          kms_key_name = var.encryption_config.secondary_kms_key_name
        }
      }

      weekly_schedule {
        days_of_week = var.automated_backup_configuration.weekly_schedule.days_of_week
        start_times {
          hours   = var.automated_backup_configuration.weekly_schedule.start_times.hours
          minutes = var.automated_backup_configuration.weekly_schedule.start_times.minutes
          seconds = var.automated_backup_configuration.weekly_schedule.start_times.seconds
          nanos   = var.automated_backup_configuration.weekly_schedule.start_times.nanos
        }
      }

      dynamic "quantity_based_retention" {
        for_each = var.automated_backup_configuration.retention_count != null ? { 1 = 1 } : {}
        content {
          count = var.automated_backup_configuration.retention_count
        }
      }

      dynamic "time_based_retention" {
        for_each = var.automated_backup_configuration.retention_period != null ? { 1 = 1 } : {}
        content {
          retention_period = var.automated_backup_configuration.retention_period
        }
      }
    }
  }

  dynamic "continuous_backup_config" {
    for_each = var.continuous_backup_configuration.enabled ? { 1 = 1 } : {}
    content {
      enabled              = true
      recovery_window_days = var.continuous_backup_configuration.recovery_window_days
      dynamic "encryption_config" {
        for_each = var.encryption_config != null ? { 1 = 1 } : {}
        content {
          kms_key_name = var.encryption_config.secondary_kms_key_name
        }
      }
    }
  }

  dynamic "encryption_config" {
    for_each = var.encryption_config != null ? { 1 = 1 } : {}
    content {
      kms_key_name = var.encryption_config.secondary_kms_key_name
    }
  }

  dynamic "initial_user" {
    for_each = var.initial_user != null ? { 1 = 1 } : {}
    content {
      user     = var.initial_user.user
      password = var.initial_user.password
    }
  }

  dynamic "maintenance_update_policy" {
    for_each = var.maintenance_config.enabled ? { 1 = 1 } : {}
    content {
      maintenance_windows {
        day = var.maintenance_config.day
        start_time {
          hours   = var.maintenance_config.start_times.hours
          minutes = var.maintenance_config.start_times.minutes
          seconds = var.maintenance_config.start_times.seconds
          nanos   = var.maintenance_config.start_times.nanos
        }
      }
    }
  }

  dynamic "secondary_config" {
    for_each = var.cross_region_replication.promote_secondary ? {} : { 1 = 1 }
    content {
      primary_cluster_name = google_alloydb_cluster.primary.id
    }
  }

  depends_on = [google_alloydb_instance.primary]
}

resource "google_alloydb_instance" "secondary" {
  count             = var.cross_region_replication.enabled ? 1 : 0
  availability_type = var.availability_type
  cluster           = google_alloydb_cluster.secondary[0].id
  database_flags    = var.cross_region_replication.promote_secondary ? var.flags : null
  display_name      = "${local.prefix}${var.name}"
  gce_zone          = local.is_regional ? null : var.gce_zone
  instance_id       = "${local.prefix}${var.name}-secondary"
  instance_type     = local.secondary_instance_type
  labels            = var.labels

  dynamic "client_connection_config" {
    for_each = var.client_connection_config != null ? { 1 = 1 } : {}
    content {
      require_connectors = var.client_connection_config.require_connectors
      dynamic "ssl_config" {
        for_each = var.client_connection_config.ssl_config != null ? { 1 = 1 } : {}
        content {
          ssl_mode = var.client_connection_config.ssl_config.ssl_mode
        }
      }
    }
  }

  dynamic "machine_config" {
    for_each = var.machine_config != null ? { 1 = 1 } : {}
    content {
      cpu_count = var.machine_config.cpu_count
    }
  }

  dynamic "network_config" {
    for_each = var.network_config != null ? { 1 = 1 } : {}
    content {
      dynamic "authorized_external_networks" {
        for_each = coalesce(var.network_config.authorized_external_networks, [])
        content {
          cidr_range = authorized_external_networks.value
        }
      }
      enable_public_ip = var.network_config.enable_public_ip
    }
  }

  dynamic "query_insights_config" {
    for_each = var.query_insights_config != null ? { 1 = 1 } : {}
    content {
      query_string_length     = var.query_insights_config.query_string_length
      record_application_tags = var.query_insights_config.record_application_tags
      record_client_address   = var.query_insights_config.record_client_address
      query_plans_per_minute  = var.query_insights_config.query_plans_per_minute
    }
  }
}

resource "random_password" "passwords" {
  for_each = toset([
    for k, v in coalesce(var.users, {}) :
    k
    if v.password == null
  ])
  length  = 16
  special = true
}

resource "google_alloydb_user" "users" {
  for_each       = local.users
  cluster        = google_alloydb_cluster.primary.id
  user_id        = each.value.name
  user_type      = each.value.type
  password       = each.value.password
  database_roles = each.value.roles
}

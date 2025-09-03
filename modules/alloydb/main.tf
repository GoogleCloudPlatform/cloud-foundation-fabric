/**
 * Copyright 2025 Google LLC
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
  prefix      = var.prefix == null ? "" : "${var.prefix}-"
  is_regional = var.availability_type == "REGIONAL"

  require_connectors = try(var.client_connection_config.require_connectors, false) ? true : null
  ssl_mode           = try(var.client_connection_config.ssl_config.ssl_mode, null)

  has_public_ip                = try(var.network_config.psa_config.enable_public_ip, false) || try(var.network_config.psa_config.enable_outbound_public_ip, false)
  authorized_external_networks = toset(try(var.network_config.psa_config.authorized_external_networks, []))
  enable_public_ip             = try(var.network_config.psa_config.enable_public_ip, false) ? true : null
  enable_outbound_public_ip    = try(var.network_config.psa_config.enable_outbound_public_ip, false) ? true : null
  allowed_consumer_projects    = try(var.network_config.psc_config.allowed_consumer_projects, [])

  primary_cluster_name    = "${local.prefix}${var.cluster_name}"
  primary_instance_name   = "${local.prefix}${var.instance_name}"
  primary_kms_key_name    = try(var.encryption_config.primary_kms_key_name, null)
  secondary_cluster_name  = coalesce(var.cross_region_replication.secondary_cluster_name, "${var.cluster_name}-sec")
  secondary_instance_name = coalesce(var.cross_region_replication.secondary_instance_name, "${var.instance_name}-sec")
  secondary_kms_key_name  = try(var.encryption_config.secondary_kms_key_name, null)
  # secondary instance type is aligned with cluster type unless apply is targeting a promotion, in that
  # case cluster will be 'primary' while instance still 'secondary'.
  secondary_instance_type = try(
    var.cross_region_replication.promote_secondary && google_alloydb_cluster.secondary[0].cluster_type == "SECONDARY"
    ? "SECONDARY"
    : google_alloydb_cluster.secondary[0].cluster_type, null
  )
  secondary_machine_type = (
    try(var.cross_region_replication.secondary_machine_config.machine_type, null) != null
    ? var.cross_region_replication.secondary_machine_config.machine_type
    : var.machine_config.machine_type
  )

  read_pool = {
    for name, instance in var.read_pool : name => merge(instance, {
      require_connectors = try(instance.client_connection_config.require_connectors, false) ? true : null
      ssl_mode           = try(instance.client_connection_config.ssl_config.ssl_mode, null)
    })
  }
}

resource "google_alloydb_cluster" "primary" {
  project                          = var.project_id
  annotations                      = var.annotations
  cluster_id                       = local.primary_cluster_name
  cluster_type                     = var.cross_region_replication.switchover_mode ? "SECONDARY" : "PRIMARY"
  database_version                 = var.database_version
  deletion_policy                  = var.deletion_policy
  deletion_protection              = var.deletion_protection
  display_name                     = coalesce(var.cluster_display_name, local.primary_cluster_name)
  labels                           = var.labels
  location                         = var.location
  skip_await_major_version_upgrade = var.skip_await_major_version_upgrade
  subscription_type                = var.subscription_type

  # network_config block should exist only when PSA VPC resource link is present to prevent Terraform state drift
  dynamic "network_config" {
    for_each = var.network_config.psa_config != null ? [""] : []
    content {
      network            = var.network_config.psa_config.network
      allocated_ip_range = var.network_config.psa_config.allocated_ip_range
    }
  }

  dynamic "automated_backup_policy" {
    for_each = var.automated_backup_configuration.enabled ? [""] : []
    content {
      enabled       = true
      location      = try(var.automated_backup_configuration.location, var.location)
      backup_window = var.automated_backup_configuration.backup_window
      labels        = var.labels

      dynamic "encryption_config" {
        for_each = local.primary_kms_key_name != null ? [""] : []
        content {
          kms_key_name = local.primary_kms_key_name
        }
      }

      weekly_schedule {
        days_of_week = var.automated_backup_configuration.weekly_schedule.days_of_week
        start_times {
          hours   = var.automated_backup_configuration.weekly_schedule.start_times.hours
          minutes = 0
          seconds = 0
          nanos   = 0
        }
      }

      dynamic "quantity_based_retention" {
        for_each = var.automated_backup_configuration.retention_count != null ? [""] : []
        content {
          count = var.automated_backup_configuration.retention_count
        }
      }

      dynamic "time_based_retention" {
        for_each = var.automated_backup_configuration.retention_period != null ? [""] : []
        content {
          retention_period = var.automated_backup_configuration.retention_period
        }
      }
    }
  }

  continuous_backup_config {
    enabled              = var.continuous_backup_configuration.enabled
    recovery_window_days = var.continuous_backup_configuration.recovery_window_days
    dynamic "encryption_config" {
      for_each = local.primary_kms_key_name != null ? [""] : []
      content {
        kms_key_name = local.primary_kms_key_name
      }
    }
  }

  dynamic "encryption_config" {
    for_each = local.primary_kms_key_name != null ? [""] : []
    content {
      kms_key_name = local.primary_kms_key_name
    }
  }

  dynamic "initial_user" {
    for_each = var.initial_user != null ? [""] : []
    content {
      user     = var.initial_user.user
      password = var.initial_user.password
    }
  }

  dynamic "maintenance_update_policy" {
    for_each = var.maintenance_config.enabled ? [""] : []
    content {
      maintenance_windows {
        day = var.maintenance_config.day
        start_time {
          hours   = var.maintenance_config.start_time.hours
          minutes = 0
          seconds = 0
          nanos   = 0
        }
      }
    }
  }

  # psc_config block should exist only when PSC is enabled to prevent Terraform state drift
  dynamic "psc_config" {
    for_each = length(local.allowed_consumer_projects) > 0 ? [""] : []
    content {
      psc_enabled = true
    }
  }

  dynamic "secondary_config" {
    for_each = var.cross_region_replication.switchover_mode ? [""] : []
    content {
      primary_cluster_name = "projects/${var.project_id}/locations/${var.cross_region_replication.region}/clusters/${local.secondary_cluster_name}"
    }
  }

  # waiting to fix this issue https://github.com/hashicorp/terraform-provider-google/issues/14944
  lifecycle {
    ignore_changes = [
      display_name,
    ]
  }
}

resource "google_alloydb_instance" "primary" {
  provider          = google-beta
  annotations       = var.annotations
  availability_type = var.availability_type
  cluster           = google_alloydb_cluster.primary.id
  database_flags    = var.flags
  display_name      = coalesce(var.display_name, local.primary_instance_name)
  instance_id       = local.primary_instance_name
  instance_type     = var.cross_region_replication.switchover_mode ? "SECONDARY" : "PRIMARY"
  gce_zone          = local.is_regional ? null : var.gce_zone
  labels            = var.labels

  dynamic "client_connection_config" {
    for_each = local.require_connectors != null || local.ssl_mode != null ? [""] : []
    content {
      require_connectors = local.require_connectors
      dynamic "ssl_config" {
        for_each = local.ssl_mode != null ? [""] : []
        content {
          ssl_mode = local.ssl_mode
        }
      }
    }
  }

  machine_config {
    cpu_count    = var.machine_config.cpu_count
    machine_type = var.machine_config.machine_type
  }

  # network_config block should exist only when (outbound) public IP is enabled to prevent Terraform state drift
  dynamic "network_config" {
    for_each = local.has_public_ip ? [""] : []
    content {
      dynamic "authorized_external_networks" {
        for_each = local.authorized_external_networks
        content {
          cidr_range = authorized_external_networks.value
        }
      }
      enable_public_ip          = local.enable_public_ip
      enable_outbound_public_ip = local.enable_outbound_public_ip
    }
  }

  # psc_instance_config block should exist only when there are PSC allowed consumer projects to prevent Terraform state drift
  dynamic "psc_instance_config" {
    for_each = length(local.allowed_consumer_projects) > 0 ? [""] : []
    content {
      allowed_consumer_projects = local.allowed_consumer_projects
    }
  }

  dynamic "query_insights_config" {
    for_each = var.query_insights_config != null ? [""] : []
    content {
      query_string_length     = var.query_insights_config.query_string_length
      record_application_tags = var.query_insights_config.record_application_tags
      record_client_address   = var.query_insights_config.record_client_address
      query_plans_per_minute  = var.query_insights_config.query_plans_per_minute
    }
  }
}

resource "google_alloydb_cluster" "secondary" {
  count                            = var.cross_region_replication.enabled ? 1 : 0
  project                          = var.project_id
  annotations                      = var.annotations
  cluster_id                       = local.secondary_cluster_name
  cluster_type                     = var.cross_region_replication.promote_secondary || var.cross_region_replication.switchover_mode ? "PRIMARY" : "SECONDARY"
  database_version                 = var.database_version
  deletion_policy                  = "FORCE"
  display_name                     = coalesce(var.cross_region_replication.secondary_cluster_display_name, local.secondary_cluster_name)
  labels                           = var.labels
  location                         = var.cross_region_replication.region
  skip_await_major_version_upgrade = var.skip_await_major_version_upgrade
  subscription_type                = var.subscription_type

  # network_config block should exist only when PSA VPC resource link is present to prevent Terraform state drift
  dynamic "network_config" {
    for_each = var.network_config.psa_config != null ? [""] : []
    content {
      network            = var.network_config.psa_config.network
      allocated_ip_range = var.network_config.psa_config.allocated_ip_range
    }
  }

  dynamic "automated_backup_policy" {
    for_each = var.automated_backup_configuration.enabled ? [""] : []
    content {
      enabled       = true
      location      = var.cross_region_replication.region
      backup_window = var.automated_backup_configuration.backup_window
      labels        = var.labels

      dynamic "encryption_config" {
        for_each = local.secondary_kms_key_name != null ? [""] : []
        content {
          kms_key_name = local.secondary_kms_key_name
        }
      }

      weekly_schedule {
        days_of_week = var.automated_backup_configuration.weekly_schedule.days_of_week
        start_times {
          hours   = var.automated_backup_configuration.weekly_schedule.start_times.hours
          minutes = 0
          seconds = 0
          nanos   = 0
        }
      }

      dynamic "quantity_based_retention" {
        for_each = var.automated_backup_configuration.retention_count != null ? [""] : []
        content {
          count = var.automated_backup_configuration.retention_count
        }
      }

      dynamic "time_based_retention" {
        for_each = var.automated_backup_configuration.retention_period != null ? [""] : []
        content {
          retention_period = var.automated_backup_configuration.retention_period
        }
      }
    }
  }

  continuous_backup_config {
    enabled              = var.continuous_backup_configuration.enabled
    recovery_window_days = var.continuous_backup_configuration.recovery_window_days
    dynamic "encryption_config" {
      for_each = local.secondary_kms_key_name != null ? [""] : []
      content {
        kms_key_name = local.secondary_kms_key_name
      }
    }
  }

  dynamic "encryption_config" {
    for_each = local.secondary_kms_key_name != null ? [""] : []
    content {
      kms_key_name = local.secondary_kms_key_name
    }
  }

  dynamic "maintenance_update_policy" {
    for_each = var.maintenance_config.enabled ? [""] : []
    content {
      maintenance_windows {
        day = var.maintenance_config.day
        start_time {
          hours   = var.maintenance_config.start_time.hours
          minutes = 0
          seconds = 0
          nanos   = 0
        }
      }
    }
  }

  # psc_config block should exist only when PSC is enabled to prevent Terraform state drift
  dynamic "psc_config" {
    for_each = length(local.allowed_consumer_projects) > 0 ? [""] : []
    content {
      psc_enabled = true
    }
  }

  dynamic "secondary_config" {
    for_each = var.cross_region_replication.promote_secondary || var.cross_region_replication.switchover_mode ? [] : [""]
    content {
      primary_cluster_name = google_alloydb_cluster.primary.id
    }
  }

  depends_on = [google_alloydb_instance.primary]

  # waiting to fix this issue https://github.com/hashicorp/terraform-provider-google/issues/14944
  lifecycle {
    ignore_changes = [
      display_name,
    ]
  }
}

resource "google_alloydb_instance" "secondary" {
  provider          = google-beta
  count             = var.cross_region_replication.enabled ? 1 : 0
  annotations       = var.annotations
  availability_type = var.availability_type
  cluster           = google_alloydb_cluster.secondary[0].id
  database_flags    = var.cross_region_replication.promote_secondary || var.cross_region_replication.switchover_mode ? var.flags : null
  display_name      = coalesce(var.cross_region_replication.secondary_instance_name, local.secondary_instance_name)
  gce_zone          = local.is_regional ? null : var.gce_zone
  instance_id       = local.secondary_instance_name
  instance_type     = local.secondary_instance_type
  labels            = var.labels

  dynamic "client_connection_config" {
    for_each = local.require_connectors != null || local.ssl_mode != null ? [""] : []
    content {
      require_connectors = local.require_connectors
      dynamic "ssl_config" {
        for_each = local.ssl_mode != null ? [""] : []
        content {
          ssl_mode = local.ssl_mode
        }
      }
    }
  }

  machine_config {
    cpu_count    = coalesce(try(var.cross_region_replication.secondary_machine_config.cpu_count, null), var.machine_config.cpu_count)
    machine_type = local.secondary_machine_type
  }

  # network_config block should exist only when (outbound) public IP is enabled to prevent Terraform state drift
  dynamic "network_config" {
    for_each = local.has_public_ip ? [""] : []
    content {
      dynamic "authorized_external_networks" {
        for_each = local.authorized_external_networks
        content {
          cidr_range = authorized_external_networks.value
        }
      }
      enable_public_ip          = local.enable_public_ip
      enable_outbound_public_ip = local.enable_outbound_public_ip
    }
  }

  # psc_instance_config block should exist only when there are PSC allowed consumer projects to prevent Terraform state drift
  dynamic "psc_instance_config" {
    for_each = length(local.allowed_consumer_projects) > 0 ? [""] : []
    content {
      allowed_consumer_projects = local.allowed_consumer_projects
    }
  }

  dynamic "query_insights_config" {
    for_each = var.query_insights_config != null ? [""] : []
    content {
      query_string_length     = var.query_insights_config.query_string_length
      record_application_tags = var.query_insights_config.record_application_tags
      record_client_address   = var.query_insights_config.record_client_address
      query_plans_per_minute  = var.query_insights_config.query_plans_per_minute
    }
  }
}

# Read pool (instance_type = "READ_POOL") cannot be created for secondary cluster
# and does not support the following attributes:
# * availability_type: Because 1 node pool (read_pool_config.node_count) is always zonal, two or more is always regional.
# * gce_zone
# * network_config.enable_outbound_public_ip
resource "google_alloydb_instance" "read_pool" {
  provider       = google-beta
  for_each       = local.read_pool
  annotations    = var.annotations
  cluster        = google_alloydb_cluster.primary.id
  database_flags = each.value.flags
  display_name   = coalesce(each.value.display_name, "${local.prefix}${each.key}")
  instance_id    = "${local.prefix}${each.key}"
  instance_type  = "READ_POOL"
  labels         = var.labels

  dynamic "client_connection_config" {
    for_each = each.value.require_connectors != null || each.value.ssl_mode != null ? [""] : []
    content {
      require_connectors = each.value.require_connectors
      dynamic "ssl_config" {
        for_each = each.value.ssl_mode != null ? [""] : []
        content {
          ssl_mode = each.value.ssl_mode
        }
      }
    }
  }

  machine_config {
    cpu_count    = each.value.machine_config.cpu_count
    machine_type = each.value.machine_config.machine_type
  }

  # network_config block should exist only when (outbound) public IP is enabled to prevent Terraform state drift
  dynamic "network_config" {
    for_each = each.value.network_config.enable_public_ip ? [""] : []
    content {
      dynamic "authorized_external_networks" {
        for_each = toset(each.value.network_config.authorized_external_networks)
        content {
          cidr_range = authorized_external_networks.value
        }
      }
      enable_public_ip = true
    }
  }

  # psc_instance_config block should exist only when there are PSC allowed consumer projects to prevent Terraform state drift
  dynamic "psc_instance_config" {
    for_each = length(local.allowed_consumer_projects) > 0 ? [""] : []
    content {
      allowed_consumer_projects = local.allowed_consumer_projects
    }
  }

  read_pool_config {
    node_count = each.value.node_count
  }

  dynamic "query_insights_config" {
    for_each = each.value.query_insights_config != null ? [""] : []
    content {
      query_string_length     = each.value.query_insights_config.query_string_length
      record_application_tags = each.value.query_insights_config.record_application_tags
      record_client_address   = each.value.query_insights_config.record_client_address
      query_plans_per_minute  = each.value.query_insights_config.query_plans_per_minute
    }
  }

  depends_on = [google_alloydb_instance.primary]
}

resource "random_password" "passwords" {
  for_each = {
    for k, v in var.users :
    k => v
    if v.type == "ALLOYDB_BUILT_IN" && v.password == null
  }
  length  = 16
  special = true
}

resource "google_alloydb_user" "users" {
  for_each  = var.users
  cluster   = google_alloydb_cluster.primary.id
  user_id   = each.key
  user_type = each.value.type
  password = (
    each.value.type == "ALLOYDB_BUILT_IN" && each.value.password == null ?
    random_password.passwords[each.key].result
    : each.value.password
  )
  database_roles = each.value.roles
  depends_on     = [google_alloydb_instance.primary]
}

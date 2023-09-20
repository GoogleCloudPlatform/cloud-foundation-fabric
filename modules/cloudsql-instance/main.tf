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
  prefix       = var.prefix == null ? "" : "${var.prefix}-"
  is_mysql     = can(regex("^MYSQL", var.database_version))
  has_replicas = try(length(var.replicas) > 0, false)
  is_regional  = var.availability_type == "REGIONAL" ? true : false

  // Enable backup if the user asks for it or if the user is deploying
  // MySQL in HA configuration (regional or with specified replicas)
  enable_backup = var.backup_configuration.enabled || (local.is_mysql && local.has_replicas) || (local.is_mysql && local.is_regional)

  users = {
    for user, password in coalesce(var.users, {}) :
    (user) => (
      local.is_mysql
      ? {
        name     = split("@", user)[0]
        host     = try(split("@", user)[1], null)
        password = try(random_password.passwords[user].result, password)
      }
      : {
        name     = user
        host     = null
        password = try(random_password.passwords[user].result, password)
      }
    )
  }

}

resource "google_sql_database_instance" "primary" {
  provider            = google-beta
  project             = var.project_id
  name                = "${local.prefix}${var.name}"
  region              = var.region
  database_version    = var.database_version
  encryption_key_name = var.encryption_key_name
  root_password       = var.root_password

  settings {
    tier                        = var.tier
    deletion_protection_enabled = var.deletion_protection_enabled
    disk_autoresize             = var.disk_size == null
    disk_size                   = var.disk_size
    disk_type                   = var.disk_type
    availability_type           = var.availability_type
    user_labels                 = var.labels
    activation_policy           = var.activation_policy

    ip_configuration {
      ipv4_enabled       = var.ipv4_enabled
      private_network    = var.network
      allocated_ip_range = var.allocated_ip_ranges.primary
      require_ssl        = var.require_ssl
      dynamic "authorized_networks" {
        for_each = var.authorized_networks != null ? var.authorized_networks : {}
        iterator = network
        content {
          name  = network.key
          value = network.value
        }
      }
    }

    dynamic "backup_configuration" {
      for_each = local.enable_backup ? { 1 = 1 } : {}
      content {
        enabled = true

        // enable binary log if the user asks for it or we have replicas (default in regional),
        // but only for MySQL
        binary_log_enabled = (
          local.is_mysql
          ? var.backup_configuration.binary_log_enabled || local.has_replicas || local.is_regional
          : null
        )
        start_time                     = var.backup_configuration.start_time
        location                       = var.backup_configuration.location
        point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
        transaction_log_retention_days = var.backup_configuration.log_retention_days
        backup_retention_settings {
          retained_backups = var.backup_configuration.retention_count
          retention_unit   = "COUNT"
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.flags != null ? var.flags : {}
      iterator = flag
      content {
        name  = flag.key
        value = flag.value
      }
    }

    dynamic "insights_config" {
      for_each = var.insights_config != null ? [1] : []
      content {
        query_insights_enabled  = true
        query_string_length     = var.insights_config.query_string_length
        record_application_tags = var.insights_config.record_application_tags
        record_client_address   = var.insights_config.record_client_address
        query_plans_per_minute  = var.insights_config.query_plans_per_minute
      }
    }
  }
  deletion_protection = var.deletion_protection
}

resource "google_sql_database_instance" "replicas" {
  provider             = google-beta
  for_each             = local.has_replicas ? var.replicas : {}
  project              = var.project_id
  name                 = "${local.prefix}${each.key}"
  region               = each.value.region
  database_version     = var.database_version
  encryption_key_name  = each.value.encryption_key_name
  master_instance_name = google_sql_database_instance.primary.name

  settings {
    tier                        = var.tier
    deletion_protection_enabled = var.deletion_protection_enabled
    disk_autoresize             = var.disk_size == null
    disk_size                   = var.disk_size
    disk_type                   = var.disk_type
    # availability_type = var.availability_type
    user_labels       = var.labels
    activation_policy = var.activation_policy

    ip_configuration {
      ipv4_enabled       = var.ipv4_enabled
      private_network    = var.network
      allocated_ip_range = var.allocated_ip_ranges.replica
      dynamic "authorized_networks" {
        for_each = var.authorized_networks != null ? var.authorized_networks : {}
        iterator = network
        content {
          name  = network.key
          value = network.value
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.flags != null ? var.flags : {}
      iterator = flag
      content {
        name  = flag.key
        value = flag.value
      }
    }
  }
  deletion_protection = var.deletion_protection
}

resource "google_sql_database" "databases" {
  for_each = var.databases != null ? toset(var.databases) : toset([])
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  name     = each.key
}

resource "random_password" "passwords" {
  for_each = toset([
    for user, password in coalesce(var.users, {}) :
    user
    if password == null
  ])
  length  = 16
  special = true
}

resource "google_sql_user" "users" {
  for_each = local.users
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  name     = each.value.name
  host     = each.value.host
  password = each.value.password
}

resource "google_sql_ssl_cert" "postgres_client_certificates" {
  for_each    = var.postgres_client_certificates != null ? toset(var.postgres_client_certificates) : toset([])
  provider    = google-beta
  project     = var.project_id
  instance    = google_sql_database_instance.primary.name
  common_name = each.key
}

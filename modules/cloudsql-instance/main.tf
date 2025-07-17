/** TO MOD
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
  prefix       = var.prefix == null ? "" : "${var.prefix}-"
  is_mysql     = can(regex("^MYSQL", var.database_version))
  is_postgres  = can(regex("^POSTGRES", var.database_version))
  has_replicas = length(var.replicas) > 0
  is_regional  = var.availability_type == "REGIONAL" ? true : false
  users = {
    for k, v in var.users : k =>
    local.is_mysql
    ? {
      name     = v.type == "BUILT_IN" ? split("@", k)[0] : k
      host     = v.type == "BUILT_IN" ? try(split("@", k)[1], null) : null
      password = v.type == "BUILT_IN" ? try(random_password.passwords[k].result, v.password) : null
      type     = v.type
    }
    : {
      name     = local.is_postgres ? try(trimsuffix(k, ".gserviceaccount.com"), k) : k
      host     = null
      password = v.type == "BUILT_IN" ? try(random_password.passwords[k].result, v.password) : null
      type     = v.type
    }
  }
}

resource "google_sql_database_instance" "primary" {
  provider            = google-beta
  project             = var.project_id
  name                = "${local.prefix}${var.name}"
  region              = var.region
  database_version    = var.database_version
  encryption_key_name = var.encryption_key_name
  root_password       = var.root_password.random_password ? random_password.root_password[0].result : var.root_password.password

  settings {
    tier                        = var.tier
    edition                     = var.edition
    deletion_protection_enabled = var.gcp_deletion_protection
    disk_autoresize             = var.disk_size == null
    disk_autoresize_limit       = var.disk_autoresize_limit
    disk_size                   = var.disk_size
    disk_type                   = var.disk_type
    availability_type           = var.availability_type
    user_labels                 = var.labels
    activation_policy           = var.activation_policy
    collation                   = var.collation
    connector_enforcement       = var.connector_enforcement
    time_zone                   = var.time_zone

    ip_configuration {
      ipv4_enabled = var.network_config.connectivity.public_ipv4
      private_network = try(
        var.network_config.connectivity.psa_config.private_network, null
      )
      allocated_ip_range = try(
        var.network_config.connectivity.psa_config.allocated_ip_ranges.primary, null
      )
      ssl_mode = var.ssl.mode
      enable_private_path_for_google_cloud_services = (
        var.network_config.connectivity.enable_private_path_for_services
      )
      dynamic "authorized_networks" {
        for_each = (
          var.network_config.authorized_networks != null
          ? var.network_config.authorized_networks
          : {}
        )
        iterator = network
        content {
          name  = network.key
          value = network.value
        }
      }
      dynamic "psc_config" {
        for_each = (
          var.network_config.connectivity.psc_allowed_consumer_projects != null
          ? [""]
          : []
        )
        content {
          psc_enabled = true
          allowed_consumer_projects = (
            var.network_config.connectivity.psc_allowed_consumer_projects
          )
        }
      }
    }

    dynamic "backup_configuration" {
      for_each = var.backup_configuration.enabled ? { 1 = 1 } : {}
      content {
        enabled = true
        // enable binary log if the user asks for it or we have replicas (default in regional),
        // but only for MySQL
        binary_log_enabled = (
          local.is_mysql
          ? var.backup_configuration.binary_log_enabled || local.has_replicas || local.is_regional
          : null
        )
        start_time = var.backup_configuration.start_time
        location   = var.backup_configuration.location
        point_in_time_recovery_enabled = (
          var.backup_configuration.point_in_time_recovery_enabled
        )
        transaction_log_retention_days = (
          var.backup_configuration.log_retention_days
        )
        backup_retention_settings {
          retained_backups = var.backup_configuration.retention_count
          retention_unit   = "COUNT"
        }
      }
    }

    dynamic "data_cache_config" {
      for_each = var.edition == "ENTERPRISE_PLUS" ? [1] : []
      content {
        data_cache_enabled = var.data_cache
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

    dynamic "deny_maintenance_period" {
      for_each = var.maintenance_config.deny_maintenance_period != null ? [1] : []
      content {
        start_date = var.maintenance_config.deny_maintenance_period.start_date
        end_date   = var.maintenance_config.deny_maintenance_period.end_date
        time       = var.maintenance_config.deny_maintenance_period.start_time
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

    dynamic "maintenance_window" {
      for_each = var.maintenance_config.maintenance_window != null ? [""] : []
      content {
        day          = var.maintenance_config.maintenance_window.day
        hour         = var.maintenance_config.maintenance_window.hour
        update_track = var.maintenance_config.maintenance_window.update_track
      }
    }

    dynamic "password_validation_policy" {
      for_each = var.password_validation_policy != null ? [""] : []
      content {
        complexity = (
          var.password_validation_policy.default_complexity == true
          ? "COMPLEXITY_DEFAULT"
          : null # "COMPLEXITY_UNSPECIFIED" generates a permadiff
        )
        disallow_username_substring = (
          var.password_validation_policy.disallow_username_substring
        )
        enable_password_policy = var.password_validation_policy.enabled
        min_length             = var.password_validation_policy.min_length
        password_change_interval = (
          var.password_validation_policy.change_interval == null
          ? null
          : "${var.password_validation_policy.change_interval}s"
        )
        reuse_interval = var.password_validation_policy.reuse_interval
      }
    }
  }
  deletion_protection = var.terraform_deletion_protection
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
    edition                     = var.edition
    deletion_protection_enabled = var.gcp_deletion_protection
    disk_autoresize             = var.disk_size == null
    disk_autoresize_limit       = var.disk_autoresize_limit
    disk_size                   = var.disk_size
    disk_type                   = var.disk_type
    availability_type           = each.value.availability_type
    user_labels                 = var.labels
    activation_policy           = var.activation_policy
    collation                   = var.collation
    connector_enforcement       = var.connector_enforcement
    time_zone                   = var.time_zone


    ip_configuration {
      ipv4_enabled = (
        var.network_config.connectivity.public_ipv4
      )
      private_network = (
        try(var.network_config.connectivity.psa_config.private_network, null)
      )
      allocated_ip_range = try(
        var.network_config.connectivity.psa_config.allocated_ip_ranges.replica, null
      )
      ssl_mode = var.ssl.mode
      enable_private_path_for_google_cloud_services = (
        var.network_config.connectivity.enable_private_path_for_services
      )
      dynamic "authorized_networks" {
        for_each = (
          var.network_config.authorized_networks != null
          ? var.network_config.authorized_networks
          : {}
        )
        iterator = network
        content {
          name  = network.key
          value = network.value
        }
      }
      dynamic "psc_config" {
        for_each = (
          var.network_config.connectivity.psc_allowed_consumer_projects != null
          ? [""]
          : []
        )
        content {
          psc_enabled = true
          allowed_consumer_projects = (
            var.network_config.connectivity.psc_allowed_consumer_projects
          )
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
  deletion_protection = var.terraform_deletion_protection
}

resource "google_sql_database" "databases" {
  for_each = var.databases != null ? toset(var.databases) : toset([])
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  name     = each.key
}

resource "random_password" "passwords" {
  for_each = toset([
    for k, v in var.users :
    k
    if v.password == null && v.type == "BUILT_IN"
  ])
  length      = try(var.password_validation_policy.min_length, 16)
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "random_password" "root_password" {
  count       = var.root_password.random_password ? 1 : 0
  length      = try(var.password_validation_policy.min_length, 16)
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "google_sql_user" "users" {
  for_each = local.users
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  name     = each.value.name
  host     = each.value.host
  password = each.value.password
  type     = each.value.type
}

moved {
  from = google_sql_ssl_cert.postgres_client_certificates
  to   = google_sql_ssl_cert.client_certificates
}

resource "google_sql_ssl_cert" "client_certificates" {
  for_each = (
    var.ssl.client_certificates != null
    ? toset(var.ssl.client_certificates)
    : toset([])
  )
  provider    = google-beta
  project     = var.project_id
  instance    = google_sql_database_instance.primary.name
  common_name = each.key
}

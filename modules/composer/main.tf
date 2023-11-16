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
  image         = try(split("-", var.software_config.image_version), "")
  version       = try(split(".", local.image.1), null)
  major_version = try(local.version.0, 2)
  mid_version   = try(local.version.1, 1)
  min_version   = try(local.version.2, 15)

  node_count       = local.major_version == 1 ? var.node_count : null
  environment_size = local.major_version == 2 ? var.environment_size : null
  resilience_mode  = (local.major_version == 2 && local.mid_version >= 1 && local.min_version >= 15) ? var.resilience_mode : null

}


resource "google_composer_environment" "composer-env" {
  name    = var.name
  region  = var.region
  project = var.project_id

  config {
    node_count       = local.node_count       # ONLY COMPOSER 1
    environment_size = local.environment_size # ONLY COMPOSER 2
    resilience_mode  = local.resilience_mode  # ONLY COMPOSER >= 2.1.15

    dynamic "node_config" {
      for_each = var.node_config != null ? [""] : []
      content {
        zone                 = var.node_config.zone
        machine_type         = var.node_config.machine_type
        network              = var.node_config.network
        subnetwork           = var.node_config.subnetwork
        disk_size_gb         = var.node_config.disk_size_gb
        oauth_scopes         = var.node_config.oauth_scopes
        service_account      = var.node_config.service_account
        tags                 = var.node_config.tags
        ip_allocation_policy = var.node_config.ip_allocation_policy
        # max_pods_per_node = "" # BETA FEATURES - DISABLED
        enable_ip_masq_agent = var.node_config.enable_ip_masq_agent
      }
    }

    dynamic "recovery_config" {                                                        # ONLY COMPOSER 2
      for_each = (var.recovery_config != null && local.major_version == 2) ? [""] : [] # max 1
      content {
        dynamic "scheduled_snapshots_config" {
          for_each = var.recovery_config.scheduled_snapshots_config != null ? [""] : [] # max 1
          content {
            enabled                    = var.recovery_config.scheduled_snapshots_config.enabled
            snapshot_location          = var.recovery_config.scheduled_snapshots_config.snapshot_location
            snapshot_creation_schedule = var.recovery_config.scheduled_snapshots_config.snapshot_creation_schedule
            time_zone                  = var.recovery_config.scheduled_snapshots_config.time_zone
          }
        }
      }
    }

    dynamic "software_config" {
      for_each = var.software_config != null ? [""] : [] # max 1
      content {
        airflow_config_overrides = var.software_config.airflow_config_overrides
        pypi_packages            = var.software_config.pypi_packages
        env_variables            = var.software_config.env_variables
        image_version            = var.software_config.image_version
        python_version           = var.software_config.python_version
        scheduler_count          = var.software_config.scheduler_count
      }
    }

    dynamic "private_environment_config" {
      for_each = var.private_environment_config != null ? [""] : [] # max 1
      content {
        connection_type                  = var.private_environment_config.connection_type
        enable_private_endpoint          = var.private_environment_config.enable_private_endpoint
        master_ipv4_cidr_block           = var.private_environment_config.master_ipv4_cidr_block
        cloud_sql_ipv4_cidr_block        = var.private_environment_config.cloud_sql_ipv4_cidr_block
        web_server_ipv4_cidr_block       = var.private_environment_config.web_server_ipv4_cidr_block
        enable_privately_used_public_ips = var.private_environment_config.enable_privately_used_public_ips
      }
    }

    dynamic "web_server_network_access_control" {                                       # ONLY COMPOSER 1
      for_each = (var.allowed_ip_range != null && local.major_version == 1) ? [""] : [] # max 1
      content {
        dynamic "allowed_ip_range" {
          for_each = var.allowed_ip_range
          content {
            value       = allowed_ip_range.value
            description = allowed_ip_range.description
          }

        }
      }
    }

    dynamic "database_config" {                                                        # ONLY COMPOSER 1
      for_each = (var.database_config != null && local.major_version == 1) ? [""] : [] # max 1
      content {
        machine_type = var.database_config.machine_type
      }
    }

    dynamic "web_server_config" {
      for_each = (var.web_server_config != null && local.major_version == 1) ? [""] : [] # max 1
      content {
        machine_type = var.web_server_config.machine_type
      }
    }

    dynamic "encryption_config" {
      for_each = var.encryption_config != null ? [""] : [] # max 1
      content {
        kms_key_name = var.encryption_config.kms_key_name
      }
    }

    dynamic "maintenance_window" {                                                        # ONLY COMPOSER 2, BETA FOR COMPOSER 1
      for_each = (var.maintenance_window != null && local.major_version == 2) ? [""] : [] # max 1
      content {
        start_time = var.maintenance_window.start_time
        end_time   = var.maintenance_window.end_time
        recurrence = var.maintenance_window.recurrence
      }
    }

    dynamic "master_authorized_networks_config" {
      for_each = var.master_authorized_networks_config != null ? [""] : [] # max 1
      content {
        enabled = true
        dynamic "cidr_blocks" {
          for_each = var.master_authorized_networks_config.cidr_blocks
          content {
            display_name = cidr_blocks.display_name
            cidr_block   = cidr_blocks.cidr_block
          }
        }
      }
    }

    dynamic "workloads_config" {                                                        # ONLY COMPOSER 2
      for_each = (var.workloads_config != null && local.major_version == 2) ? [""] : [] # max 1
      content {
        dynamic "scheduler" {
          for_each = var.workloads_config.scheduler != null ? [""] : [] # max 1
          content {
            cpu        = var.workloads_config.scheduler.cpu
            count      = var.workloads_config.scheduler.count
            memory_gb  = var.workloads_config.scheduler.memory_gb
            storage_gb = var.workloads_config.scheduler.storage_gb
          }
        }
        dynamic "triggerer" {
          for_each = var.workloads_config.triggerer != null ? [""] : [] # max 1
          content {
            cpu       = var.workloads_config.triggerer.cpu
            memory_gb = var.workloads_config.triggerer.memory_gb
            count     = var.workloads_config.triggerer.count
          }
        }
        dynamic "web_server" {
          for_each = var.workloads_config.web_server != null ? [""] : [] # max 1
          content {
            cpu        = var.workloads_config.web_server.cpu
            memory_gb  = var.workloads_config.web_server.memory_gb
            storage_gb = var.workloads_config.web_server.storage_gb
          }
        }
        dynamic "worker" {
          for_each = var.workloads_config.web_server != null ? [""] : [] # max 1
          content {
            cpu        = var.workloads_config.worker.cpu
            memory_gb  = var.workloads_config.worker.memory_gb
            storage_gb = var.workloads_config.worker.storage_gb
            min_count  = var.workloads_config.worker.min_count
            max_count  = var.workloads_config.worker.max_count
          }
        }
      }
    }
  }
}

    
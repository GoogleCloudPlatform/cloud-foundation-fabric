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
  spanner_instance = var.instance_create ? google_spanner_instance.spanner_instance[0] : data.google_spanner_instance.spanner_instance[0]
}

resource "google_spanner_instance_config" "spanner_instance_config" {
  count        = try(var.instance.config.auto_create, null) == null ? 0 : 1
  name         = var.instance.config.name
  project      = var.project_id
  display_name = coalesce(var.instance.config.auto_create.display_name, var.instance.config.name)
  base_config  = var.instance.config.auto_create.base_config
  dynamic "replicas" {
    for_each = var.instance.config.auto_create.replicas
    content {
      location                = replicas.value.location
      type                    = replicas.value.type
      default_leader_location = replicas.value.default_leader_location
    }
  }
  labels = var.instance.config.auto_create.labels
}

data "google_spanner_instance" "spanner_instance" {
  count   = var.instance_create ? 0 : 1
  project = var.project_id
  name    = var.instance.name
}

resource "google_spanner_instance" "spanner_instance" {
  count            = var.instance_create ? 1 : 0
  project          = var.project_id
  config           = var.instance.config.auto_create == null ? var.instance.config.name : google_spanner_instance_config.spanner_instance_config[0].name
  name             = var.instance.name
  display_name     = coalesce(var.instance.display_name, var.instance.name)
  num_nodes        = var.instance.num_nodes
  labels           = var.instance.labels
  force_destroy    = var.instance.force_destroy
  processing_units = var.instance.processing_units
  dynamic "autoscaling_config" {
    for_each = var.instance.autoscaling == null ? [] : [""]
    content {
      dynamic "autoscaling_limits" {
        for_each = var.instance.autoscaling.limits == null ? [] : [""]
        content {
          max_processing_units = var.instance.autoscaling.limits.max_processing_units
          min_processing_units = var.instance.autoscaling.limits.min_processing_units
        }
      }
      dynamic "autoscaling_targets" {
        for_each = var.instance.autoscaling.targets == null ? [] : [""]
        content {
          high_priority_cpu_utilization_percent = var.instance.autoscaling.targets.high_priority_cpu_utilization_percent
          storage_utilization_percent           = var.instance.autoscaling.targets.storage_utilization_percent
        }
      }
    }
  }
}

resource "google_spanner_database" "spanner_databases" {
  for_each                 = var.databases
  project                  = var.project_id
  instance                 = local.spanner_instance.name
  name                     = each.key
  ddl                      = each.value.ddl
  enable_drop_protection   = each.value.enable_drop_protection
  deletion_protection      = false
  version_retention_period = each.value.version_retention_period
  dynamic "encryption_config" {
    for_each = each.value.kms_key_name == null ? [] : [""]
    content {
      kms_key_name = each.value.kms_key_name
    }
  }
}

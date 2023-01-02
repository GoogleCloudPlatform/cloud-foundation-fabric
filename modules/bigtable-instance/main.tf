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
  gc_pairs = flatten([
    for table, table_obj in var.tables : [
      for cf, cf_obj in table_obj.column_families : {
        table         = table
        column_family = cf
        gc_policy     = cf_obj.gc_policy == null ? var.default_gc_policy : cf_obj.gc_policy
      }
    ]
  ])

  clusters_autoscaling = {
    for cluster_id, cluster in var.clusters : cluster_id => {
      zone         = cluster.zone
      storage_type = cluster.storage_type
      num_nodes    = cluster.autoscaling == null && var.default_autoscaling == null ? cluster.num_nodes : null
      autoscaling  = cluster.autoscaling == null ? var.default_autoscaling : cluster.autoscaling
    }
  }
}

resource "google_bigtable_instance" "default" {
  project = var.project_id
  name    = var.name

  instance_type       = var.instance_type
  display_name        = var.display_name == null ? var.display_name : var.name
  deletion_protection = var.deletion_protection

  dynamic "cluster" {
    for_each = local.clusters_autoscaling
    content {
      cluster_id   = cluster.key
      zone         = cluster.value.zone
      storage_type = cluster.value.storage_type
      num_nodes    = cluster.value.num_nodes

      dynamic "autoscaling_config" {
        for_each = cluster.value.autoscaling == null ? [] : [""]
        content {
          min_nodes      = cluster.value.autoscaling.min_nodes
          max_nodes      = cluster.value.autoscaling.max_nodes
          cpu_target     = cluster.value.autoscaling.cpu_target
          storage_target = cluster.value.autoscaling.storage_target
        }
      }
    }
  }
}

resource "google_bigtable_instance_iam_binding" "default" {
  for_each = var.iam
  project  = var.project_id
  instance = google_bigtable_instance.default.name
  role     = each.key
  members  = each.value
}

resource "google_bigtable_table" "default" {
  for_each      = var.tables
  project       = var.project_id
  instance_name = google_bigtable_instance.default.name
  name          = each.key
  split_keys    = each.value.split_keys

  dynamic "column_family" {
    for_each = each.value.column_families

    content {
      family = column_family.key
    }
  }
}

resource "google_bigtable_gc_policy" "default" {
  for_each = { for k, v in local.gc_pairs : k => v if v.gc_policy != null }

  table         = each.value.table
  column_family = each.value.column_family
  instance_name = google_bigtable_instance.default.name
  project       = var.project_id

  gc_rules        = try(each.value.gc_policy.gc_rules, null)
  mode            = try(each.value.gc_policy.mode, null)
  deletion_policy = try(each.value.gc_policy.deletion_policy, null)

  dynamic "max_age" {
    for_each = try(each.value.gc_policy.max_age, null) != null ? [""] : []
    content {
      duration = each.value.gc_policy.max_age
    }
  }

  dynamic "max_version" {
    for_each = try(each.value.gc_policy.max_version, null) != null ? [""] : []
    content {
      number = each.value.gc_policy.max_version
    }
  }
}

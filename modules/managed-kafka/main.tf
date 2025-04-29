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

resource "google_managed_kafka_cluster" "cluster" {
  project    = var.project_id
  cluster_id = var.cluster_id
  location   = var.location
  labels     = var.labels
  capacity_config {
    vcpu_count   = var.capacity_config.vcpu_count
    memory_bytes = var.capacity_config.memory_bytes
  }
  gcp_config {
    access_config {
      dynamic "network_configs" {
        for_each = var.subnets
        iterator = subnet
        content {
          subnet = subnet.value
        }
      }
    }
    kms_key = var.kms_key
  }
  dynamic "rebalance_config" {
    for_each = var.rebalance_mode == null ? [] : [""]
    content {
      mode = var.rebalance_config.mode
    }
  }
}

resource "google_managed_kafka_topic" "topics" {
  for_each           = var.topics
  project            = var.project_id
  topic_id           = each.key
  cluster            = google_managed_kafka_cluster.cluster.cluster_id
  location           = var.location
  partition_count    = each.value.partition_count
  replication_factor = each.value.replication_factor
  configs            = each.value.configs
}

resource "google_managed_kafka_connect_cluster" "connect_clusters" {
  provider           = google-beta
  for_each           = var.connect_clusters
  kafka_cluster      = google_managed_kafka_cluster.cluster.id
  connect_cluster_id = each.key
  project            = coalesce(each.value.project_id, var.project_id)
  location           = coalesce(each.value.location, var.location)
  capacity_config {
    vcpu_count   = each.value.vcpu_count
    memory_bytes = each.value.memory_bytes
  }
  gcp_config {
    access_config {
      network_configs {
        primary_subnet     = each.value.primary_subnet
        additional_subnets = each.value.additional_subnets
        dns_domain_names   = each.value.dns_domain_names
      }
    }
  }
  labels = each.value.labels
}

resource "google_managed_kafka_connector" "connectors" {
  provider        = google-beta
  for_each        = var.connect_connectors
  connector_id    = each.key
  project         = google_managed_kafka_connect_cluster.connect_clusters[each.value.connect_cluster].project
  connect_cluster = google_managed_kafka_connect_cluster.connect_clusters[each.value.connect_cluster].connect_cluster_id
  location        = google_managed_kafka_connect_cluster.connect_clusters[each.value.connect_cluster].location
  configs         = merge(each.value.configs, { name = each.key })
  dynamic "task_restart_policy" {
    for_each = each.value.task_restart_policy == null ? [] : [""]
    content {
      minimum_backoff = each.value.task_restart_policy.minimum_backoff
      maximum_backoff = each.value.task_restart_policy.maximum_backoff
    }
  }
}

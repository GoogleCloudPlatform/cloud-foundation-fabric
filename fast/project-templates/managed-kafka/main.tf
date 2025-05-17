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

data "google_project" "service_project" {
  project_id = var.project_id
}

resource "google_project_service" "managed_kafka_api" {
  project            = var.project_id
  service            = "managedkafka.googleapis.com"
  disable_on_destroy = false
}


resource "google_project_iam_member" "managed_kafka_service_agent" {
  for_each = toset(var.network_project_ids)

  project = each.value
  role    = "roles/managedkafka.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.service_project.number}@gcp-sa-managedkafka.iam.gserviceaccount.com"
}

resource "time_sleep" "wait_for_api_and_iam" {
  depends_on = [
    google_project_service.managed_kafka_api,
    google_project_iam_member.managed_kafka_service_agent
  ]
  create_duration = "60s"
}
/******************************************
  Resources configuration
 *****************************************/


resource "google_managed_kafka_cluster" "kafka_cluster" {
  depends_on = [time_sleep.wait_for_api_and_iam]
  project    = var.project_id
  cluster_id = var.kafka_config.cluster_id
  location   = var.kafka_config.region

  capacity_config {
    vcpu_count   = var.kafka_config.vcpu_count
    memory_bytes = var.kafka_config.memory_bytes
  }

  gcp_config {
    access_config {
      dynamic "network_configs" {
        for_each = var.kafka_config.subnetworks
        content {
          subnet = network_configs.value
        }
      }
    }
  }

  rebalance_config {
    mode = var.kafka_config.rebalance_mode
  }

  labels = var.labels
}

resource "google_managed_kafka_topic" "topics" {
  for_each = tomap(
    var.topics != [] ? { for topic in var.topics : topic.topic_id => topic } : {}
  )
  topic_id           = each.value.topic_id
  cluster            = google_managed_kafka_cluster.kafka_cluster.cluster_id
  location           = var.kafka_config.region
  project            = var.project_id
  partition_count    = each.value.partition_count
  replication_factor = each.value.replication_factor
  configs            = each.value.configs
}
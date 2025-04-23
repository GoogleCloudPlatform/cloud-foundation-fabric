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

output "connect_cluster_ids" {
  description = "Map of Kafka Connect cluster IDs."
  value = {
    for k, v in google_managed_kafka_connect_cluster.connect_clusters :
    k => v.id
  }
}

output "connect_connectors" {
  description = "Map of Kafka Connect Connector IDs."
  value = {
    for k, v in google_managed_kafka_connector.connectors :
    k => v.id
  }
}

output "id" {
  description = "The ID of the Managed Kafka cluster."
  value       = google_managed_kafka_cluster.cluster.id
}

output "topic_ids" {
  description = "Map of Kafka topic IDs."
  value = {
    for k, v in google_managed_kafka_topic.topics :
    k => v.id
  }
}

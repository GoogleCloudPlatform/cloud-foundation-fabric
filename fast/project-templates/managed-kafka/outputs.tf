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
# Output variable definitions
output "kafka_cluster_id" {
  description = "The ID of the Kafka cluster"
  value       = google_managed_kafka_cluster.kafka_cluster.cluster_id
}

output "kafka_region" {
  description = "The region where the Kafka cluster is deployed"
  value       = google_managed_kafka_cluster.kafka_cluster.location
}

output "kafka_labels" {
  description = "Labels applied to the Kafka cluster"
  value       = google_managed_kafka_cluster.kafka_cluster.labels
}

output "project_number" {
  value = data.google_project.service_project.number
}
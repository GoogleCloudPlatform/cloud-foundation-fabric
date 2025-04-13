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
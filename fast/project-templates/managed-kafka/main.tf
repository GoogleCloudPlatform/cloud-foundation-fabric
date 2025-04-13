

data "google_project" "service_project" {
  project_id = var.project_id
}

resource "google_project_service" "managed_kafka_api" {
  project = var.project_id
  service = "managedkafka.googleapis.com"
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
  cluster_id = var.kafka_cluster_id
  location   = var.kafka_region

  capacity_config {
    vcpu_count   = var.kafka_vcpu_count
    memory_bytes = var.kafka_memory_bytes
  }

  gcp_config {
    access_config {
      dynamic "network_configs" {
        for_each = var.kafka_subnetworks
        content {
          subnet = network_configs.value
        }
      }
    }
  }

  rebalance_config {
    mode = var.kafka_rebalance_mode
  }

  labels = var.labels
}

resource "google_managed_kafka_topic" "topics" {
  for_each = tomap(
    var.topics != [] ? { for topic in var.topics : topic.topic_id => topic } : {}
  )
  topic_id           = each.value.topic_id
  cluster            = google_managed_kafka_cluster.kafka_cluster.cluster_id
  location           = var.kafka_region
  project            = var.project_id
  partition_count    = each.value.partition_count
  replication_factor = each.value.replication_factor
  configs            = each.value.configs
}
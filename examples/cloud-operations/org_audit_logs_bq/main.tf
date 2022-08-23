locals {
  final_method_list = join(" OR ", [for m in var.method_list : "\"${m}\""])
}

resource "google_logging_organization_sink" "my_org_sink" {
  name             = "tf-demo-cloud-identity-sink"
  description      = "This sink routes Audit Logs related to Cloud Identity changes to a Pub Sub in a target project"
  org_id           = var.org_id
  include_children = true
  destination      = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.my_audit_log_topic.name}"
  filter           = "protoPayload.methodName:(${local.final_method_list})"
}

resource "google_pubsub_topic" "my_audit_log_topic" {
  name                       = "tf-demo-audit-log-topic"
  project                    = var.project_id
  message_retention_duration = "86600s"
}

resource "google_project_iam_member" "org_sa_pub_sub_role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.my_org_sink.writer_identity
}


resource "google_eventarc_trigger" "my_audit_log_trigger" {
  name            = "tf-demo-trigger"
  location        = var.region
  service_account = google_service_account.eventarc_trigger_sa.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"

  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.cloud_run_event_receiver.name
      region  = var.region

    }
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.my_audit_log_topic.name
    }
  }
  depends_on = [google_project_service.eventarc]
}

resource "google_project_iam_member" "eventarc_trigger_role_binding" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_trigger_sa.email}"
}

resource "google_cloud_run_service" "cloud_run_event_receiver" {
  name     = "tf-demo-eventarc-target"
  location = var.region

  template {
    spec {
      containers {
        image = var.container_configuration.image
        ports {
          container_port = var.container_configuration.container_port
        }
      }
      container_concurrency = var.container_configuration.container_concurrency
      timeout_seconds       = var.container_configuration.timeout_seconds
    }
  }

  traffic {
    percent         = var.container_configuration.traffic_percent
    latest_revision = var.container_configuration.latest_revision
  }
}

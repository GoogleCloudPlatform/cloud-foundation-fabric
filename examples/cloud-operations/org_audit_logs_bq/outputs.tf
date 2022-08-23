output "eventarc_trigger_name" {
  value = google_eventarc_trigger.my_audit_log_trigger.name
}

output "log_sink_name" {
  value = google_logging_organization_sink.my_org_sink.name
}

output "topic_name" {
  value = google_pubsub_topic.my_audit_log_topic.name
}

output "cloud_run_name" {
  value = google_cloud_run_service.cloud_run_event_receiver.name
}
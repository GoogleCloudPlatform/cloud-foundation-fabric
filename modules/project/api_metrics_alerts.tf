resource "google_monitoring_notification_channel" "email" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  display_name = "Default Email Notification"
  type         = "email"
  labels = {
    email_address = var.api_alerts.email
  }
}

#
# Route Changes Metric and Policy
#
resource "google_logging_metric" "route_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "resource.type=\"gce_route\" AND (protoPayload.methodName:\"compute.routes.delete\" OR protoPayload.methodName:\"compute.routes.insert\")"
  name        = "network-route-config-changes"
  description = "Monitor VPC network route configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "route_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "Network Route Changes"
  conditions {
    display_name = "Network Route Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.route_changes[count.index].name}\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# Firewall Changes Metric and Policy
#
resource "google_logging_metric" "firewall_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "resource.type=\"gce_firewall_rule\" AND (protoPayload.methodName:\"compute.firewalls.insert\" OR protoPayload.methodName:\"compute.firewalls.patch\" OR protoPayload.methodName:\"compute.firewalls.delete\")"
  name        = "network-firewall-config-changes"
  description = "Monitor VPC network firewall configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "firewall_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "VPC Network Firewalls Changes"
  conditions {
    display_name = "VPC Network Firewalls Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.firewall_changes[count.index].name}\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# VPC Changes Metric and Policy
#
resource "google_logging_metric" "vpc_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "resource.type=\"gce_network\" AND (protoPayload.methodName:\"compute.networks.insert\" OR protoPayload.methodName:\"compute.networks.patch\" OR protoPayload.methodName:\"compute.networks.delete\" OR protoPayload.methodName:\"compute.networks.removePeering\" OR protoPayload.methodName:\"compute.networks.addPeering\")"
  name        = "vpc-network-config-changes"
  description = "Monitor VPC network configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "vpc_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "VPC Network Changes"
  conditions {
    display_name = "VPC Network Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "resource.type = \"global\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.vpc_changes[count.index].name}\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# CloudSQL Changes
#
resource "google_logging_metric" "cloudsql_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "protoPayload.methodName=\"cloudsql.instances.update\" OR protoPayload.methodName=\"cloudsql.instances.create\" OR protoPayload.methodName=\"cloudsql.instances.delete\""
  name        = "cloudsql-changes"
  description = "Monitor Cloud SQL configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "cloudsql_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "CloudSQL Changes"
  conditions {
    display_name = "CloudSQL Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "metric.type = \"logging.googleapis.com/user/${google_logging_metric.cloudsql_changes[count.index].name}\" AND resource.type=\"global\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# Cloud Storage IAM Changes
#
resource "google_logging_metric" "cloudstorage_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "resource.type=gcs_bucket AND protoPayload.methodName=\"storage.setIamPermissions\""
  name        = "cloudstorage-changes"
  description = "Monitor Cloud Storage IAM configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "cloudstorage_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "CloudStorage IAM Changes"
  conditions {
    display_name = "CloudStorage IAM Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "resource.type = \"gcs_bucket\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.cloudstorage_changes[count.index].name}\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# Custom Role IAM Changes
#
resource "google_logging_metric" "customrole_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "resource.type=\"iam_role\" AND (protoPayload.methodName=\"google.iam.admin.v1.CreateRole\" OR protoPayload.methodName=\"google.iam.admin.v1.DeleteRole\" OR protoPayload.methodName=\"google.iam.admin.v1.UpdateRole\")"
  name        = "customrole-changes"
  description = "Monitor IAM Custom Role configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "customrole_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "IAM Custom Role Changes"
  conditions {
    display_name = "IAM Custom Role Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "metric.type = \"logging.googleapis.com/user/${google_logging_metric.customrole_changes[count.index].name}\" AND resource.type=\"global\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# Audit Configuration Changes
#
resource "google_logging_metric" "audit_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "protoPayload.methodName=\"SetIamPolicy\" AND protoPayload.serviceData.policyDelta.auditConfigDeltas:*"
  name        = "audit-changes"
  description = "Monitor Audit configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "audit_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "Audit Configuration Changes"
  conditions {
    display_name = "Audit Configuration Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "metric.type = \"logging.googleapis.com/user/${google_logging_metric.audit_changes[count.index].name}\" AND resource.type=\"global\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

#
# IAM Owner Configuration Changes
#
resource "google_logging_metric" "owner_changes" {
  count       = var.api_alerts.enabled ? 1 : 0
  project     = local.project.project_id
  filter      = "(protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\") AND (ProjectOwnership OR projectOwnerInvitee) OR (protoPayload.serviceData.policyDelta.bindingDeltas.action=\"REMOVE\" AND protoPayload.serviceData.policyDelta.bindingDeltas.role=\"roles/owner\") OR (protoPayload.serviceData.policyDelta.bindingDeltas.action=\"ADD\" AND protoPayload.serviceData.policyDelta.bindingDeltas.role=\"roles/owner\")"
  name        = "iam-owner-changes"
  description = "Monitor IAM Owner configuration changes inside GCP projects"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "owner_changes" {
  count        = var.api_alerts.enabled ? 1 : 0
  project      = local.project.project_id
  combiner     = "OR"
  display_name = "Owner IAM Configuration Changes"
  conditions {
    display_name = "Owner IAM Configuration Changed"
    condition_threshold {
      comparison = "COMPARISON_GT"
      duration   = "0s"
      filter     = "metric.type = \"logging.googleapis.com/user/${google_logging_metric.owner_changes[count.index].name}\" AND resource.type=\"global\""
      trigger {
        count = 1
      }
      aggregations {
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
        alignment_period     = "600s"
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email[count.index].id,
  ]
  alert_strategy {
    auto_close = "604800s"
  }
}

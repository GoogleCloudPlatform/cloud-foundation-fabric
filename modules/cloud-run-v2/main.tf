/**
 * Copyright 2023 Google LLC
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
  connector = (
    var.vpc_connector_create != null
    ? google_vpc_access_connector.connector[0].id
    : try(var.revision.vpc_access.connector, null)
  )
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  revision_name = (
    var.revision.name == null ? null : "${var.name}-${var.revision.name}"
  )
  service_account_email = (
    var.service_account_create
    ? (
      length(google_service_account.service_account) > 0
      ? google_service_account.service_account[0].email
      : null
    )
    : var.service_account
  )
  trigger_sa_create = try(
    var.eventarc_triggers.service_account_create, false
  )
  trigger_sa_email = try(
    google_service_account.trigger_service_account[0].email,
    var.eventarc_triggers.service_account_email,
    null
  )
}

resource "google_cloud_run_v2_service_iam_member" "default" {
  # if authoritative invoker role is not present and we create trigger sa
  # use additive binding to grant it the role
  count = (
    lookup(var.iam, "roles/run.invoker", null) == null &&
    local.trigger_sa_create
  ) ? 1 : 0
  project  = google_cloud_run_v2_service.service[0].project
  location = google_cloud_run_v2_service.service[0].location
  name     = google_cloud_run_v2_service.service[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cr-${var.name}"
  display_name = "Terraform Cloud Run ${var.name}."
}

resource "google_eventarc_trigger" "audit_log_triggers" {
  for_each = coalesce(var.eventarc_triggers.audit_log, tomap({}))
  name     = "${local.prefix}audit-log-${each.key}"
  location = google_cloud_run_v2_service.service[0].location
  project  = google_cloud_run_v2_service.service[0].project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.audit.log.v1.written"
  }
  matching_criteria {
    attribute = "serviceName"
    value     = each.value.service
  }
  matching_criteria {
    attribute = "methodName"
    value     = each.value.method
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.service[0].name
      region  = google_cloud_run_v2_service.service[0].location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_eventarc_trigger" "pubsub_triggers" {
  for_each = coalesce(var.eventarc_triggers.pubsub, tomap({}))
  name     = "${local.prefix}pubsub-${each.key}"
  location = google_cloud_run_v2_service.service[0].location
  project  = google_cloud_run_v2_service.service[0].project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  transport {
    pubsub {
      topic = each.value
    }
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.service[0].name
      region  = google_cloud_run_v2_service.service[0].location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_service_account" "trigger_service_account" {
  count        = local.trigger_sa_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cr-trigger-${var.name}"
  display_name = "Terraform trigger for Cloud Run ${var.name}."
}

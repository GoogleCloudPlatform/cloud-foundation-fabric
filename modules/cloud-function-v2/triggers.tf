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

locals {
  trigger_sa_create = (
    try(var.eventarc_triggers.service_account_create, false) == true
  )
  trigger_sa_email = try(
    google_service_account.trigger_service_account[0].email,
    var.eventarc_triggers.service_account_email,
    null
  )
}

resource "google_eventarc_trigger" "audit_log_triggers" {
  for_each = coalesce(var.eventarc_triggers.audit_log, tomap({}))
  name     = "${local.prefix}audit-log-${each.key}"
  location = google_cloud_run_v2_service.function.location
  project  = google_cloud_run_v2_service.function.project
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
      service = google_cloud_run_v2_service.function.name
      region  = google_cloud_run_v2_service.function.location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_eventarc_trigger" "pubsub_triggers" {
  for_each = coalesce(var.eventarc_triggers.pubsub, tomap({}))
  name     = "${local.prefix}pubsub-${each.key}"
  location = google_cloud_run_v2_service.function.location
  project  = google_cloud_run_v2_service.function.project
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
      service = google_cloud_run_v2_service.function.name
      region  = google_cloud_run_v2_service.function.location
    }
  }
  service_account = local.trigger_sa_email
}

resource "google_service_account" "trigger_service_account" {
  count        = local.trigger_sa_create ? 1 : 0
  project      = var.project_id
  account_id   = "cr-trigger-${var.name}"
  display_name = "Trigger for Cloud Run ${var.name}."
}

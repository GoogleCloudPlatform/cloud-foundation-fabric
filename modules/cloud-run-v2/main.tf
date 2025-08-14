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
  connector = (
    var.vpc_connector_create != null
    ? google_vpc_access_connector.connector[0].id
    : try(var.revision.vpc_access.connector, null)
  )
  _invoke_command = {
    JOB        = <<-EOT
      gcloud run jobs execute \
        --project ${var.project_id} \
        --region ${var.region} \
        --wait ${local.resource.name} \
        --args=
    EOT
    WORKERPOOL = ""
    SERVICE    = <<-EOT
    curl -H "Authorization: bearer $(gcloud auth print-identity-token)" \
        ${local.resource.uri} \
        -X POST -d 'data'
    EOT
  }
  invoke_command = local._invoke_command[var.type]

  revision_name = (
    var.revision.name == null ? null : "${var.name}-${var.revision.name}"
  )
  service_account_email = (
    var.service_account_create
    ? google_service_account.service_account[0].email
    : var.service_account
  )
  _resource = {
    "JOB" : (
      var.managed_revision ?
      try(google_cloud_run_v2_job.job[0], null) : try(google_cloud_run_v2_job.job_unmanaged[0], null)
    )
    "WORKERPOOL" : (
      var.managed_revision ?
      try(google_cloud_run_v2_worker_pool.default_managed[0], null) : try(google_cloud_run_v2_worker_pool.default_unmanaged[0], null)
    )
    "SERVICE" : (
      var.managed_revision ?
      try(google_cloud_run_v2_service.service[0], null) : try(google_cloud_run_v2_service.service_unmanaged[0], null)
    )
  }
  resource = {
    id       = local._resource[var.type].id
    location = local._resource[var.type].location
    name     = local._resource[var.type].name
    project  = local._resource[var.type].project
    uri      = var.type == "SERVICE" ? local._resource[var.type].uri : ""
  }
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cr-${var.name}"
  display_name = "Terraform Cloud Run ${var.name}."
}

resource "google_eventarc_trigger" "audit_log_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.audit_log, tomap({}))
  name     = "audit-log-${each.key}"
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
  service_account = var.service_config.eventarc_triggers.service_account_email
}

resource "google_eventarc_trigger" "pubsub_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.pubsub, tomap({}))
  name     = "pubsub-${each.key}"
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
  service_account = var.service_config.eventarc_triggers.service_account_email
}

resource "google_eventarc_trigger" "storage_triggers" {
  for_each = coalesce(var.service_config.eventarc_triggers.storage, tomap({}))
  name     = "storage-${each.key}"
  location = google_cloud_run_v2_service.service[0].location
  project  = google_cloud_run_v2_service.service[0].project
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = each.value.bucket
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.service[0].name
      region  = google_cloud_run_v2_service.service[0].location
      path    = try(each.value.path, null)
    }
  }
  service_account = var.service_config.eventarc_triggers.service_account_email
}

/**
 * Copyright 2022 Google LLC
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
  bucket = (
    var.bucket_name != null
    ? var.bucket_name
    : (
      length(google_storage_bucket.bucket) > 0
      ? google_storage_bucket.bucket[0].name
      : null
    )
  )
  function = (
    var.v2
    ? google_cloudfunctions2_function.function[0]
    : google_cloudfunctions_function.function[0]
  )
  prefix                = var.prefix == null ? "" : "${var.prefix}-"
  service_account_email = var.service_account_create ? google_service_account.service_account[0].email : var.service_account
  trigger_service_account_email = (
    coalesce(try(var.trigger_config.v2.service_account_create, false), false)
    ? google_service_account.trigger_service_account[0].email
    : null
  )
  vpc_connector = (
    var.vpc_connector == null
    ? null
    : (
      try(var.vpc_connector.create, false) == false
      ? var.vpc_connector.name
      : google_vpc_access_connector.connector.0.id
    )
  )
}

resource "google_vpc_access_connector" "connector" {
  count         = try(var.vpc_connector.create, false) == false ? 0 : 1
  project       = var.project_id
  name          = var.vpc_connector.name
  region        = var.region
  ip_cidr_range = var.vpc_connector_config.ip_cidr_range
  network       = var.vpc_connector_config.network
}

resource "google_cloudfunctions_function" "function" {
  count                 = var.v2 ? 0 : 1
  project               = var.project_id
  region                = var.region
  name                  = "${local.prefix}${var.name}"
  description           = var.description
  runtime               = var.function_config.runtime
  available_memory_mb   = var.function_config.memory_mb
  max_instances         = var.function_config.instance_count
  timeout               = var.function_config.timeout_seconds
  entry_point           = var.function_config.entry_point
  environment_variables = var.environment_variables
  service_account_email = local.service_account_email
  source_archive_bucket = local.bucket
  source_archive_object = google_storage_bucket_object.bundle.name
  labels                = var.labels
  trigger_http          = var.trigger_config.v1 == null ? true : null

  ingress_settings  = var.ingress_settings
  build_worker_pool = var.build_worker_pool

  vpc_connector = local.vpc_connector
  vpc_connector_egress_settings = try(
    var.vpc_connector.egress_settings, null
  )

  dynamic "event_trigger" {
    for_each = var.trigger_config.v1 == null ? [] : [""]
    content {
      event_type = var.trigger_config.v1.event
      resource   = var.trigger_config.v1.resource
      dynamic "failure_policy" {
        for_each = var.trigger_config.v1.retry == null ? [] : [""]
        content {
          retry = var.trigger_config.v1.retry
        }
      }
    }
  }

  dynamic "secret_environment_variables" {
    for_each = { for k, v in var.secrets : k => v if !v.is_volume }
    iterator = secret
    content {
      key        = secret.key
      project_id = secret.value.project_id
      secret     = secret.value.secret
      version    = try(secret.value.versions.0, "latest")
    }
  }

  dynamic "secret_volumes" {
    for_each = { for k, v in var.secrets : k => v if v.is_volume }
    iterator = secret
    content {
      mount_path = secret.key
      project_id = secret.value.project_id
      secret     = secret.value.secret
      dynamic "versions" {
        for_each = secret.value.versions
        iterator = version
        content {
          path    = split(":", version)[1]
          version = split(":", version)[0]
        }
      }
    }
  }
}

resource "google_cloudfunctions2_function" "function" {
  count       = var.v2 ? 1 : 0
  provider    = google-beta
  project     = var.project_id
  location    = var.region
  name        = "${local.prefix}${var.name}"
  description = var.description
  build_config {
    worker_pool           = var.build_worker_pool
    runtime               = var.function_config.runtime
    entry_point           = "${var.function_config.entry_point}_http" # Set the entry point 
    environment_variables = var.environment_variables
    source {
      storage_source {
        bucket = local.bucket
        object = google_storage_bucket_object.bundle.name
      }
    }
  }
  dynamic "event_trigger" {
    for_each = var.trigger_config.v2 == null ? [] : [""]
    content {
      trigger_region = var.trigger_config.v2.region
      event_type     = var.trigger_config.v2.event_type
      pubsub_topic   = var.trigger_config.v2.pubsub_topic
      dynamic "event_filters" {
        for_each = var.trigger_config.v2.event_filters == null ? [] : var.trigger_config.v2.event_filters
        iterator = event_filter
        content {
          attribute = event_filter.attribute
          value     = event_filter.value
          operator  = event_filter.operator
        }
      }
      service_account_email = var.trigger_config.v2.service_account_email
      retry_policy          = var.trigger_config.v2.retry_policy
    }
  }
  service_config {
    max_instance_count             = var.function_config.instance_count
    min_instance_count             = 0
    available_memory               = "${var.function_config.memory_mb}M"
    timeout_seconds                = var.function_config.timeout_seconds
    environment_variables          = var.environment_variables
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = true
    service_account_email          = local.service_account_email
    vpc_connector                  = local.vpc_connector
    vpc_connector_egress_settings = try(
    var.vpc_connector.egress_settings, null)

    dynamic "secret_environment_variables" {
      for_each = { for k, v in var.secrets : k => v if !v.is_volume }
      iterator = secret
      content {
        key        = secret.key
        project_id = secret.value.project_id
        secret     = secret.value.secret
        version    = try(secret.value.versions.0, "latest")
      }
    }

    dynamic "secret_volumes" {
      for_each = { for k, v in var.secrets : k => v if v.is_volume }
      iterator = secret
      content {
        mount_path = secret.key
        project_id = secret.value.project_id
        secret     = secret.value.secret
        dynamic "versions" {
          for_each = secret.value.versions
          iterator = version
          content {
            path    = split(":", version)[1]
            version = split(":", version)[0]
          }
        }
      }
    }
  }
  labels = var.labels
}

resource "google_cloudfunctions_function_iam_binding" "default" {
  for_each       = !var.v2 ? var.iam : {}
  project        = var.project_id
  region         = var.region
  cloud_function = local.function.name
  role           = each.key
  members        = each.value
}

resource "google_cloudfunctions2_function_iam_binding" "default" {
  for_each       = var.v2 ? var.iam : {}
  project        = var.project_id
  location       = google_cloudfunctions2_function.function[0].location
  cloud_function = local.function.name
  role           = each.key
  members        = each.value
}

resource "google_storage_bucket" "bucket" {
  count                       = var.bucket_config == null ? 0 : 1
  project                     = var.project_id
  name                        = "${local.prefix}${var.bucket_name}"
  uniform_bucket_level_access = true
  location = (
    var.bucket_config.location == null
    ? var.region
    : var.bucket_config.location
  )
  labels = var.labels

  dynamic "lifecycle_rule" {
    for_each = var.bucket_config.lifecycle_delete_age_days == null ? [] : [""]
    content {
      action { type = "Delete" }
      condition {
        age        = var.bucket_config.lifecycle_delete_age_days
        with_state = "ARCHIVED"
      }
    }
  }

  dynamic "versioning" {
    for_each = var.bucket_config.lifecycle_delete_age_days == null ? [] : [""]
    content {
      enabled = true
    }
  }
}

resource "google_storage_bucket_object" "bundle" {
  name   = "bundle-${data.archive_file.bundle.output_md5}.zip"
  bucket = local.bucket
  source = data.archive_file.bundle.output_path
}

data "archive_file" "bundle" {
  type             = "zip"
  source_dir       = var.bundle_config.source_dir
  output_path      = var.bundle_config.output_path
  output_file_mode = "0666"
  excludes         = var.bundle_config.excludes
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cf-${var.name}"
  display_name = "Terraform Cloud Function ${var.name}."
}

resource "google_service_account" "trigger_service_account" {
  count        = coalesce(try(var.trigger_config.v2.service_account_create, false), false) ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cf-trigger-${var.name}"
  display_name = "Terraform trigger for Cloud Function ${var.name}."
}

resource "google_project_iam_member" "trigger_iam" {
  count   = coalesce(try(var.trigger_config.v2.service_account_create, false), false) ? 1 : 0
  project = var.project_id
  member  = "serviceAccount:${google_service_account.trigger_service_account[0].email}"
  role    = "roles/run.invoker"
}

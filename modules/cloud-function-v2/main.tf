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
  _ctx_p = "$"
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local._ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  bucket = (
    var.bucket_config == null
    ? var.bucket_name
    : (
      length(google_storage_bucket.bucket) > 0
      ? google_storage_bucket.bucket[0].name
      : null
    )
  )
  location   = lookup(local.ctx.locations, var.region, var.region)
  prefix     = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  trigger_sa_create = (
    try(var.trigger_config.service_account_create, false) == true
  )
  trigger_sa_email = try(
    google_service_account.trigger_service_account[0].email,
    var.trigger_config.service_account_email,
    null
  )
  vpc_connector = var.vpc_connector_create != null ? google_vpc_access_connector.connector[0].id : var.vpc_connector.name
}

resource "google_cloudfunctions2_function" "function" {
  provider     = google-beta
  project      = local.project_id
  location     = local.location
  name         = "${local.prefix}${var.name}"
  description  = var.description
  kms_key_name = var.kms_key == null ? null : lookup(local.ctx.kms_keys, var.kms_key, var.kms_key)
  build_config {
    service_account       = var.build_service_account
    worker_pool           = var.build_worker_pool
    runtime               = var.function_config.runtime
    entry_point           = var.function_config.entry_point
    environment_variables = var.build_environment_variables
    docker_repository     = var.docker_repository_id
    source {
      storage_source {
        bucket = local.bucket
        object = (
          local.bundle_type == "gcs"
          ? replace(var.bundle_config.path, "/^gs:\\/\\/[^\\/]+\\//", "")
          : google_storage_bucket_object.bundle[0].name
        )
      }
    }
  }
  dynamic "event_trigger" {
    for_each = var.trigger_config == null ? [] : [""]
    content {
      event_type   = var.trigger_config.event_type
      pubsub_topic = var.trigger_config.pubsub_topic
      trigger_region = (
        var.trigger_config.region == null
        ? var.region
        : var.trigger_config.region
      )
      dynamic "event_filters" {
        for_each = var.trigger_config.event_filters
        iterator = event_filter
        content {
          attribute = event_filter.value.attribute
          value     = event_filter.value.value
          operator  = event_filter.value.operator
        }
      }
      service_account_email = local.trigger_sa_email
      retry_policy          = var.trigger_config.retry_policy
    }
  }
  service_config {
    all_traffic_on_latest_revision = true
    available_cpu                  = var.function_config.cpu
    available_memory               = "${var.function_config.memory_mb}M"
    binary_authorization_policy    = var.function_config.binary_authorization_policy
    environment_variables          = var.environment_variables
    ingress_settings               = var.ingress_settings
    max_instance_count             = var.function_config.instance_count
    min_instance_count             = 0
    service_account_email          = local.service_account_email
    timeout_seconds                = var.function_config.timeout_seconds
    vpc_connector                  = local.vpc_connector
    vpc_connector_egress_settings  = var.vpc_connector.egress_settings

    dynamic "secret_environment_variables" {
      for_each = { for k, v in var.secrets : k => v if !v.is_volume }
      iterator = secret
      content {
        key        = secret.key
        project_id = secret.value.project_id
        secret     = secret.value.secret
        version    = try(secret.value.versions[0], "latest")
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
            path    = split(":", version.value)[1]
            version = split(":", version.value)[0]
          }
        }
      }
    }
  }
  labels = var.labels
}

resource "google_cloudfunctions2_function_iam_binding" "binding" {
  for_each = {
    for k, v in var.iam : k => v if k != "roles/run.invoker"
  }
  project        = local.project_id
  location       = local.location
  cloud_function = google_cloudfunctions2_function.function.name
  role           = lookup(local.ctx.custom_roles, each.key, each.key)
  members        = [for member in each.value : lookup(local.ctx.iam_principals, member, member)]
  lifecycle {
    replace_triggered_by = [google_cloudfunctions2_function.function]
  }
}

locals {
  run_invoker_members = distinct(compact(concat(
    !local.trigger_sa_create
    ? []
    : ["serviceAccount:${local.trigger_sa_email}"],
    lookup(var.iam, "roles/run.invoker", []),
  )))
}

resource "google_cloud_run_service_iam_binding" "invoker" {
  # cloud run resources are needed for invoker role to the underlying service
  count = (
    lookup(var.iam, "roles/run.invoker", null) != null
  ) ? 1 : 0
  project  = local.project_id
  location = local.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  members  = [for member in local.run_invoker_members : lookup(local.ctx.iam_principals, member, member)]
  lifecycle {
    replace_triggered_by = [google_cloudfunctions2_function.function]
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  # if authoritative invoker role is not present and we create trigger sa
  # use additive binding to grant it the role
  count = (
    lookup(var.iam, "roles/run.invoker", null) == null &&
    local.trigger_sa_create
  ) ? 1 : 0
  project  = local.project_id
  location = local.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
  lifecycle {
    replace_triggered_by = [google_cloudfunctions2_function.function]
  }
}

resource "google_service_account" "trigger_service_account" {
  count        = local.trigger_sa_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-cf-trigger-${var.name}"
  display_name = "Terraform trigger for Cloud Function ${var.name}."
}

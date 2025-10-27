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
  location      = lookup(local.ctx.locations, var.region, var.region)
  prefix        = var.prefix == null ? "" : "${var.prefix}-"
  project_id    = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  vpc_connector = var.vpc_connector_create != null ? google_vpc_access_connector.connector[0].id : var.vpc_connector.name
}

resource "google_cloudfunctions_function" "function" {
  project               = local.project_id
  region                = local.location
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
  source_archive_object = (
    local.bundle_type == "gcs"
    ? replace(var.bundle_config.path, "/^gs:\\/\\/[^\\/]+\\//", "")
    : google_storage_bucket_object.bundle[0].name
  )
  labels                        = var.labels
  trigger_http                  = var.trigger_config == null ? true : null
  https_trigger_security_level  = var.https_security_level == null ? "SECURE_ALWAYS" : var.https_security_level
  ingress_settings              = var.ingress_settings
  build_worker_pool             = var.build_worker_pool
  build_environment_variables   = var.build_environment_variables
  kms_key_name                  = var.kms_key == null ? null : lookup(local.ctx.kms_keys, var.kms_key, var.kms_key)
  docker_registry               = try(var.repository_settings.registry, "ARTIFACT_REGISTRY")
  docker_repository             = try(var.repository_settings.repository, null)
  vpc_connector                 = local.vpc_connector
  vpc_connector_egress_settings = var.vpc_connector.egress_settings

  dynamic "event_trigger" {
    for_each = var.trigger_config == null ? [] : [""]
    content {
      event_type = var.trigger_config.event
      resource   = var.trigger_config.resource
      dynamic "failure_policy" {
        for_each = var.trigger_config.retry == null ? [] : [""]
        content {
          retry = var.trigger_config.retry
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

resource "google_cloudfunctions_function_iam_binding" "default" {
  for_each       = var.iam
  project        = local.project_id
  region         = local.location
  cloud_function = google_cloudfunctions_function.function.id
  role           = lookup(local.ctx.custom_roles, each.key, each.key)
  members        = [for member in each.value : lookup(local.ctx.iam_principals, member, member)]
  lifecycle {
    replace_triggered_by = [google_cloudfunctions_function.function]
  }
}

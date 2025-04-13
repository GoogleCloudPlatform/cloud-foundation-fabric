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
  base_image_uri = lookup(
    local.runtime_uris,
    var.function_config.runtime,
    var.function_config.runtime
  )
  bucket = (
    var.bucket_config == null
    ? var.bucket_name
    : (
      length(google_storage_bucket.bucket) > 0
      ? google_storage_bucket.bucket[0].name
      : null
    )
  )
  prefix                 = var.prefix == null ? "" : "${var.prefix}-"
  runtime_uris_base_path = "us-central1-docker.pkg.dev/serverless-runtimes/google-22-full/runtimes"
  runtime_uris = {
    dotnet8   = "${local.runtime_uris_base_path}/dotnet8"
    go123     = "${local.runtime_uris_base_path}/go123"
    java21    = "${local.runtime_uris_base_path}/java21"
    nodejs22  = "${local.runtime_uris_base_path}/nodejs22"
    php83     = "${local.runtime_uris_base_path}/php83"
    python312 = "${local.runtime_uris_base_path}/python312"
    ruby33    = "${local.runtime_uris_base_path}/ruby33"
  }
  service_account_email = (
    var.service_account_create
    ? google_service_account.service_account[0].email
    : var.service_account
  )
  source_location = (
    local.bundle_type == "gcs"
    ? var.bundle_config.path
    : "gs://${local.bucket}/${google_storage_bucket_object.bundle[0].name}"
  )
}

resource "google_cloud_run_v2_service" "function" {
  name                = var.name
  project             = var.project_id
  location            = var.region
  description         = var.description
  deletion_protection = var.deletion_protection
  ingress             = var.ingress

  build_config {
    source_location       = local.source_location
    function_target       = var.function_config.entry_point
    image_uri             = var.image_uri
    base_image            = local.base_image_uri
    worker_pool           = var.build_worker_pool
    environment_variables = var.build_environment_variables
    service_account       = var.build_service_account
  }
  template {
    encryption_key        = var.encryption_key
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    service_account       = var.service_account
    timeout               = var.function_config.timeout
    containers {
      image          = var.image_uri
      base_image_uri = local.base_image_uri
      dynamic "env" {
        for_each = coalesce(var.environment_variables, tomap({}))
        content {
          name  = env.key
          value = env.value
        }
      }
      dynamic "env" {
        for_each = coalesce(var.secrets, tomap({}))
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }
      resources {
        limits = {
          cpu    = var.function_config.cpu
          memory = var.function_config.memory
        }
        cpu_idle = true
      }
      dynamic "volume_mounts" {
        for_each = {
          for k, v in coalesce(var.volume_mounts, tomap({}))
          : k => v if k != "cloudsql"
        }
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value
        }
      }
      # CloudSQL is the last mount in the list returned by API
      dynamic "volume_mounts" {
        for_each = {
          for k, v in coalesce(var.volume_mounts, tomap({}))
          : k => v if k == "cloudsql"
        }
        content {
          name       = volume_mounts.key
          mount_path = volume_mounts.value
        }
      }
    }
    scaling {
      max_instance_count = var.function_config.max_instance_count
      min_instance_count = 0
    }
    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances == null }
      content {
        name = volumes.key
        dynamic "secret" {
          for_each = volumes.value.secret == null ? [] : [""]
          content {
            secret       = volumes.value.secret.name
            default_mode = volumes.value.secret.default_mode
            dynamic "items" {
              for_each = volumes.value.secret.path == null ? [] : [""]
              content {
                path    = volumes.value.secret.path
                version = volumes.value.secret.version
                mode    = volumes.value.secret.mode
              }
            }
          }
        }
        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir_size == null ? [] : [""]
          content {
            medium     = "MEMORY"
            size_limit = volumes.value.empty_dir_size
          }
        }
        dynamic "gcs" {
          for_each = volumes.value.gcs == null ? [] : [""]
          content {
            bucket    = volumes.value.gcs.bucket
            read_only = volumes.value.gcs.is_read_only
          }
        }
        dynamic "nfs" {
          for_each = volumes.value.nfs == null ? [] : [""]
          content {
            server    = volumes.value.nfs.server
            path      = volumes.value.nfs.path
            read_only = volumes.value.nfs.is_read_only
          }
        }
      }
    }
    # CloudSQL is the last volume in the list returned by API
    dynamic "volumes" {
      for_each = { for k, v in var.volumes : k => v if v.cloud_sql_instances != null }
      content {
        name = volumes.key
        dynamic "cloud_sql_instance" {
          for_each = length(coalesce(volumes.value.cloud_sql_instances, [])) == 0 ? [] : [""]
          content {
            instances = volumes.value.cloud_sql_instances
          }
        }
      }
    }
    dynamic "vpc_access" {
      for_each = local.vpc_connector == null ? [] : [""]
      content {
        connector = local.vpc_connector
        egress    = var.vpc_access.egress
      }
    }
    dynamic "vpc_access" {
      for_each = (
        var.vpc_access.subnet == null
        && var.vpc_access.network == null
        ? [] : [""]
      )
      content {
        egress = var.vpc_access.egress
        network_interfaces {
          subnetwork = var.vpc_access.subnet
          network    = var.vpc_access.network
          tags       = var.vpc_access.tags
        }
      }
    }
  }
}

# resource "google_cloudfunctions2_function" "function" {
#   provider       = google-beta
#   project        = var.project_id
#   location       = var.region
#   name           = "${local.prefix}${var.name}"
#   description    = var.description
#   encryption_key = var.encryption_key
#   build_config {
#     service_account       = var.build_service_account
#     worker_pool           = var.build_worker_pool
#     runtime               = var.function_config.runtime
#     entry_point           = var.function_config.entry_point
#     environment_variables = var.build_environment_variables
#     docker_repository     = var.docker_repository_id
#     source {
#       storage_source {
#         bucket = local.bucket
#         object = (
#           local.bundle_type == "gcs"
#           ? replace(var.bundle_config.path, "/^gs:\\/\\/[^\\/]+\\//", "")
#           : google_storage_bucket_object.bundle[0].name
#         )
#       }
#     }
#   }
#   dynamic "event_trigger" {
#     for_each = var.trigger_config == null ? [] : [""]
#     content {
#       event_type   = var.trigger_config.event_type
#       pubsub_topic = var.trigger_config.pubsub_topic
#       trigger_region = (
#         var.trigger_config.region == null
#         ? var.region
#         : var.trigger_config.region
#       )
#       dynamic "event_filters" {
#         for_each = var.trigger_config.event_filters
#         iterator = event_filter
#         content {
#           attribute = event_filter.value.attribute
#           value     = event_filter.value.value
#           operator  = event_filter.value.operator
#         }
#       }
#       service_account_email = local.trigger_sa_email
#       retry_policy          = var.trigger_config.retry_policy
#     }
#   }
#   service_config {
#     max_instance_count             = var.function_config.instance_count
#     min_instance_count             = 0
#     available_memory               = "${var.function_config.memory_mb}M"
#     available_cpu                  = var.function_config.cpu
#     timeout_seconds                = var.function_config.timeout_seconds
#     environment_variables          = var.environment_variables
#     ingress_settings               = var.ingress_settings
#     all_traffic_on_latest_revision = true
#     service_account_email          = local.service_account_email
#     vpc_connector                  = local.vpc_connector
#     vpc_connector_egress_settings  = var.vpc_connector.egress_settings

#     dynamic "secret_environment_variables" {
#       for_each = { for k, v in var.secrets : k => v if !v.is_volume }
#       iterator = secret
#       content {
#         key        = secret.key
#         project_id = secret.value.project_id
#         secret     = secret.value.secret
#         version    = try(secret.value.versions[0], "latest")
#       }
#     }

#     dynamic "secret_volumes" {
#       for_each = { for k, v in var.secrets : k => v if v.is_volume }
#       iterator = secret
#       content {
#         mount_path = secret.key
#         project_id = secret.value.project_id
#         secret     = secret.value.secret
#         dynamic "versions" {
#           for_each = secret.value.versions
#           iterator = version
#           content {
#             path    = split(":", version.value)[1]
#             version = split(":", version.value)[0]
#           }
#         }
#       }
#     }
#   }
#   labels = var.labels
# }

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  for_each = {
    for k, v in var.iam : k => v if k != "roles/run.invoker"
  }
  name     = google_cloud_run_v2_service.function.name
  project  = var.project_id
  location = google_cloud_run_v2_service.function.location
  role     = each.key
  members  = each.value
  lifecycle {
    replace_triggered_by = [google_cloud_run_v2_service.function]
  }
}

resource "google_cloud_run_service_iam_binding" "invoker" {
  # cloud run resources are needed for invoker role to the underlying service
  count = (
    lookup(var.iam, "roles/run.invoker", null) != null
  ) ? 1 : 0
  project  = var.project_id
  location = google_cloud_run_v2_service.function.location
  service  = google_cloud_run_v2_service.function.id
  role     = "roles/run.invoker"
  members = distinct(compact(concat(
    lookup(var.iam, "roles/run.invoker", []),
    (
      !local.trigger_sa_create
      ? []
      : ["serviceAccount:${local.trigger_sa_email}"]
    )
  )))
  lifecycle {
    replace_triggered_by = [google_cloud_run_v2_service.function]
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  # if authoritative invoker role is not present and we create trigger sa
  # use additive binding to grant it the role
  count = (
    lookup(var.iam, "roles/run.invoker", null) == null &&
    local.trigger_sa_create
  ) ? 1 : 0
  project  = var.project_id
  location = google_cloud_run_v2_service.function.location
  service  = google_cloud_run_v2_service.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
  lifecycle {
    replace_triggered_by = [google_cloud_run_v2_service.function]
  }
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "cf-${var.name}"
  display_name = "Cloud Function ${var.name}."
}

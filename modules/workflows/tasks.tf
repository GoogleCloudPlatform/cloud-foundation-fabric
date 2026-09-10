# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "google_cloud_tasks_queue" "default" {
  for_each = var.task_queues
  provider = google
  project  = local.project_id
  name     = "${local.prefix}${each.key}"
  location = (
    each.value.location == null
    ? local.region
    : lookup(local.ctx.locations, each.value.location, each.value.location)
  )
  deletion_policy = each.value.deletion_policy

  dynamic "rate_limits" {
    for_each = each.value.rate_limits != null ? [each.value.rate_limits] : []
    content {
      max_concurrent_dispatches = rate_limits.value.max_concurrent_dispatches
      max_dispatches_per_second = rate_limits.value.max_dispatches_per_second
    }
  }

  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []
    content {
      max_attempts       = retry_config.value.max_attempts
      max_backoff        = retry_config.value.max_backoff
      max_doublings      = retry_config.value.max_doublings
      max_retry_duration = retry_config.value.max_retry_duration
      min_backoff        = retry_config.value.min_backoff
    }
  }

  dynamic "stackdriver_logging_config" {
    for_each = (
      each.value.stackdriver_logging_config != null
      ? [each.value.stackdriver_logging_config]
      : []
    )
    content {
      sampling_ratio = stackdriver_logging_config.value.sampling_ratio
    }
  }

  dynamic "http_target" {
    for_each = (
      each.value.http_target != null
      ? [each.value.http_target]
      : []
    )
    content {
      http_method = http_target.value.http_method

      dynamic "header_overrides" {
        for_each = coalesce(http_target.value.header_overrides, {})
        content {
          header {
            key   = header_overrides.key
            value = header_overrides.value
          }
        }
      }

      dynamic "oauth_token" {
        for_each = (
          http_target.value.oauth_token != null
          ? [http_target.value.oauth_token]
          : []
        )
        content {
          service_account_email = lookup(
            local.ctx.service_accounts,
            oauth_token.value.service_account_email,
            oauth_token.value.service_account_email
          )
          scope = oauth_token.value.scope
        }
      }

      dynamic "oidc_token" {
        for_each = (
          http_target.value.oidc_token != null
          ? [http_target.value.oidc_token]
          : []
        )
        content {
          service_account_email = lookup(
            local.ctx.service_accounts,
            oidc_token.value.service_account_email,
            oidc_token.value.service_account_email
          )
          audience = oidc_token.value.audience
        }
      }

      dynamic "uri_override" {
        for_each = (
          http_target.value.uri_override != null
          ? [http_target.value.uri_override]
          : []
        )
        content {
          host   = uri_override.value.host
          port   = uri_override.value.port
          scheme = uri_override.value.scheme
          uri_override_enforce_mode = (
            uri_override.value.uri_override_enforce_mode
          )

          dynamic "path_override" {
            for_each = (
              uri_override.value.path != null
              ? [uri_override.value.path]
              : []
            )
            content {
              path = path_override.value
            }
          }

          dynamic "query_override" {
            for_each = (
              uri_override.value.query_params != null
              ? [uri_override.value.query_params]
              : []
            )
            content {
              query_params = query_override.value
            }
          }
        }
      }
    }
  }
}

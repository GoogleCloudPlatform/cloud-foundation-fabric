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

locals {
  scheduler_jobs = {
    for k, v in var.scheduler_jobs : k => merge(v, {
      service_account = (
        v.service_account != null
        ? lookup(
          local.ctx.service_accounts,
          v.service_account,
          v.service_account
        )
        : local.service_account
      )
      uri = (
        v.uri != null
        ? v.uri
        : format(
          "https://workflowexecutions.googleapis.com/v1/%s/executions",
          google_workflows_workflow.default.id
        )
      )
    })
  }
}

resource "google_cloud_scheduler_job" "default" {
  for_each = local.scheduler_jobs
  provider = google
  project  = local.project_id
  name     = "${local.prefix}${each.key}"
  region = (
    each.value.region == null
    ? local.region
    : lookup(local.ctx.locations, each.value.region, each.value.region)
  )
  schedule  = each.value.schedule
  time_zone = each.value.time_zone
  description = coalesce(
    each.value.description,
    "Scheduled execution for workflow ${local.prefix}${var.name}."
  )
  paused           = each.value.paused
  attempt_deadline = each.value.attempt_deadline

  dynamic "retry_config" {
    for_each = each.value.retry_config != null ? [each.value.retry_config] : []
    content {
      retry_count          = retry_config.value.retry_count
      max_retry_duration   = retry_config.value.max_retry_duration
      min_backoff_duration = retry_config.value.min_backoff_duration
      max_backoff_duration = retry_config.value.max_backoff_duration
      max_doublings        = retry_config.value.max_doublings
    }
  }

  http_target {
    http_method = "POST"
    uri         = each.value.uri
    headers = merge(
      { "Content-Type" = "application/json" },
      coalesce(each.value.headers, {})
    )
    body = base64encode(jsonencode(
      merge(
        each.value.argument != null ? { argument = each.value.argument } : {},
        each.value.call_log_level != null
        ? { callLogLevel = each.value.call_log_level }
        : {}
      )
    ))

    dynamic "oauth_token" {
      for_each = (
        each.value.oauth_token != null
        ? [each.value.oauth_token]
        : (
          each.value.oidc_token == null && each.value.service_account != null
          ? [{
            service_account_email = each.value.service_account
            scope = (
              "https://www.googleapis.com/auth/cloud-platform"
            )
          }]
          : []
        )
      )
      content {
        service_account_email = lookup(
          local.ctx.service_accounts,
          oauth_token.value.service_account_email,
          oauth_token.value.service_account_email
        )
        scope = coalesce(
          try(oauth_token.value.scope, null),
          "https://www.googleapis.com/auth/cloud-platform"
        )
      }
    }

    dynamic "oidc_token" {
      for_each = each.value.oidc_token != null ? [each.value.oidc_token] : []
      content {
        service_account_email = lookup(
          local.ctx.service_accounts,
          oidc_token.value.service_account_email,
          oidc_token.value.service_account_email
        )
        audience = oidc_token.value.audience
      }
    }
  }
}

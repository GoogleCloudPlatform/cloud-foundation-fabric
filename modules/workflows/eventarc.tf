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

resource "google_eventarc_trigger" "default" {
  for_each = var.eventarc_triggers
  provider = google
  project  = local.project_id
  name     = "${local.prefix}${each.key}"
  location = (
    each.value.location == null
    ? local.region
    : lookup(local.ctx.locations, each.value.location, each.value.location)
  )
  labels                  = merge(var.labels, coalesce(each.value.labels, {}))
  event_data_content_type = each.value.event_data_content_type
  service_account = (
    each.value.service_account == null
    ? local.service_account
    : lookup(
      local.ctx.service_accounts,
      each.value.service_account,
      each.value.service_account
    )
  )

  destination {
    workflow = google_workflows_workflow.default.id
  }

  dynamic "matching_criteria" {
    for_each = coalesce(each.value.matching_criteria, [])
    content {
      attribute = matching_criteria.value.attribute
      value     = matching_criteria.value.value
      operator  = matching_criteria.value.operator
    }
  }

  dynamic "transport" {
    for_each = (
      each.value.pubsub_topic == null
      ? []
      : [lookup(
        local.ctx.pubsub_topics,
        each.value.pubsub_topic,
        each.value.pubsub_topic
      )]
    )
    content {
      pubsub {
        topic = transport.value
      }
    }
  }

  dynamic "retry_policy" {
    for_each = (
      each.value.retry_policy != null
      ? [each.value.retry_policy]
      : []
    )
    content {
      max_attempts = retry_policy.value.max_attempts
    }
  }
}

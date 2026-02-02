/**
 * Copyright 2026 Google LLC
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

resource "google_cloud_asset_project_feed" "default" {
  for_each = var.asset_feeds
  project  = local.project.project_id
  billing_project = lookup(
    local.ctx.project_ids,
    coalesce(each.value.billing_project, local.project.project_id),
    coalesce(each.value.billing_project, local.project.project_id)
  )
  feed_id      = each.key
  content_type = each.value.content_type

  asset_types = each.value.asset_types
  asset_names = each.value.asset_names

  feed_output_config {
    pubsub_destination {
      topic = lookup(
        local.ctx.pubsub_topics,
        each.value.feed_output_config.pubsub_destination.topic,
        each.value.feed_output_config.pubsub_destination.topic
      )
    }
  }

  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [each.value.condition]
    content {
      expression  = condition.value.expression
      title       = condition.value.title
      description = condition.value.description
      location    = condition.value.location
    }
  }
}

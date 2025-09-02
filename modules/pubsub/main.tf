/**
 * Copyright 2023 Google LLC
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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p           = "$"
  project_id      = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  topic_id_static = "projects/${var.project_id}/topics/${var.name}"
}

resource "google_pubsub_schema" "default" {
  count      = var.schema == null ? 0 : 1
  project    = local.project_id
  name       = "${var.name}-schema"
  type       = var.schema.schema_type
  definition = var.schema.definition
}

resource "google_pubsub_topic" "default" {
  project                    = local.project_id
  name                       = var.name
  kms_key_name               = var.kms_key
  labels                     = var.labels
  message_retention_duration = var.message_retention_duration
  dynamic "message_storage_policy" {
    for_each = length(var.regions) > 0 ? [var.regions] : []
    content {
      allowed_persistence_regions = [
        for v in var.regions : lookup(local.ctx.locations, v, v)
      ]
    }
  }
  dynamic "schema_settings" {
    for_each = var.schema == null ? [] : [""]
    content {
      schema   = google_pubsub_schema.default[0].id
      encoding = var.schema.msg_encoding
    }
  }
}

resource "google_pubsub_subscription" "default" {
  for_each                     = var.subscriptions
  project                      = local.project_id
  name                         = each.key
  topic                        = google_pubsub_topic.default.name
  labels                       = coalesce(each.value.labels, var.labels)
  ack_deadline_seconds         = each.value.ack_deadline_seconds
  message_retention_duration   = each.value.message_retention_duration
  retain_acked_messages        = each.value.retain_acked_messages
  filter                       = each.value.filter
  enable_message_ordering      = each.value.enable_message_ordering
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery
  dynamic "bigquery_config" {
    for_each = each.value.bigquery == null ? [] : [""]
    content {
      table                 = each.value.bigquery.table
      use_table_schema      = each.value.bigquery.use_table_schema
      use_topic_schema      = each.value.bigquery.use_topic_schema
      write_metadata        = each.value.bigquery.write_metadata
      drop_unknown_fields   = each.value.bigquery.drop_unknown_fields
      service_account_email = each.value.bigquery.service_account_email
    }
  }
  dynamic "cloud_storage_config" {
    for_each = each.value.cloud_storage == null ? [] : [""]
    content {
      bucket          = each.value.cloud_storage.bucket
      filename_prefix = each.value.cloud_storage.filename_prefix
      filename_suffix = each.value.cloud_storage.filename_suffix
      max_duration    = each.value.cloud_storage.max_duration
      max_bytes       = each.value.cloud_storage.max_bytes
      dynamic "avro_config" {
        for_each = each.value.cloud_storage.avro_config == null ? [] : [""]
        content {
          write_metadata = each.value.cloud_storage.avro_config.write_metadata
        }
      }
    }
  }
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_policy == null ? [] : [""]
    content {
      dead_letter_topic     = each.value.dead_letter_policy.topic
      max_delivery_attempts = each.value.dead_letter_policy.max_delivery_attempts
    }
  }
  dynamic "expiration_policy" {
    for_each = each.value.expiration_policy_ttl == null ? [] : [""]
    content {
      ttl = each.value.expiration_policy_ttl
    }
  }
  dynamic "push_config" {
    for_each = each.value.push == null ? [] : [""]
    content {
      push_endpoint = each.value.push.endpoint
      attributes    = each.value.push.attributes
      dynamic "no_wrapper" {
        for_each = each.value.push.no_wrapper == null ? [] : [""]
        content {
          write_metadata = each.value.push.no_wrapper.write_metadata
        }
      }
      dynamic "oidc_token" {
        for_each = each.value.push.oidc_token == null ? [] : [""]
        content {
          service_account_email = each.value.push.oidc_token.service_account_email
          audience              = each.value.push.oidc_token.audience
        }
      }
    }
  }
  dynamic "retry_policy" {
    for_each = each.value.retry_policy == null ? [] : [""]
    content {
      maximum_backoff = (
        each.value.retry_policy.maximum_backoff != null
        ? "${each.value.retry_policy.maximum_backoff}s"
        : null
      )
      minimum_backoff = (
        each.value.retry_policy.minimum_backoff != null
        ? "${each.value.retry_policy.minimum_backoff}s"
        : null
      )
    }
  }
}

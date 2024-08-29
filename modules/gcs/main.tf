/**
 * Copyright 2024 Google LLC
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
  prefix       = var.prefix == null ? "" : "${var.prefix}-"
  notification = try(var.notification_config.enabled, false)
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.prefix}${lower(var.name)}"
  project                     = var.project_id
  location                    = var.location
  storage_class               = var.storage_class
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
  labels                      = var.labels
  default_event_based_hold    = var.default_event_based_hold
  requester_pays              = var.requester_pays
  public_access_prevention    = var.public_access_prevention
  rpo                         = var.rpo

  dynamic "versioning" {
    for_each = var.versioning == null ? [] : [""]
    content {
      enabled = var.versioning
    }
  }

  dynamic "autoclass" {
    for_each = var.autoclass == null ? [] : [""]
    content {
      enabled = var.autoclass
    }
  }

  dynamic "cors" {
    for_each = var.cors == null ? [] : [""]
    content {
      origin          = var.cors.origin
      method          = var.cors.method
      response_header = var.cors.response_header
      max_age_seconds = max(3600, var.cors.max_age_seconds)
    }
  }

  dynamic "custom_placement_config" {
    for_each = var.custom_placement_config == null ? [] : [""]

    content {
      data_locations = var.custom_placement_config
    }
  }

  dynamic "encryption" {
    for_each = var.encryption_key == null ? [] : [""]

    content {
      default_kms_key_name = var.encryption_key
    }
  }

  dynamic "logging" {
    for_each = var.logging_config == null ? [] : [""]
    content {
      log_bucket        = var.logging_config.log_bucket
      log_object_prefix = var.logging_config.log_object_prefix
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    iterator = rule
    content {
      action {
        type          = rule.value.action.type
        storage_class = rule.value.action.storage_class
      }
      condition {
        age                        = rule.value.condition.age
        created_before             = rule.value.condition.created_before
        custom_time_before         = rule.value.condition.custom_time_before
        days_since_custom_time     = rule.value.condition.days_since_custom_time
        days_since_noncurrent_time = rule.value.condition.days_since_noncurrent_time
        matches_prefix             = rule.value.condition.matches_prefix
        matches_storage_class      = rule.value.condition.matches_storage_class
        matches_suffix             = rule.value.condition.matches_suffix
        noncurrent_time_before     = rule.value.condition.noncurrent_time_before
        num_newer_versions         = rule.value.condition.num_newer_versions
        with_state                 = rule.value.condition.with_state
      }
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy == null ? [] : [""]
    content {
      retention_period = var.retention_policy.retention_period
      is_locked        = var.retention_policy.is_locked
    }
  }

  dynamic "soft_delete_policy" {
    for_each = var.soft_delete_retention == null ? [] : [""]
    content {
      retention_duration_seconds = var.soft_delete_retention
    }
  }

  dynamic "website" {
    for_each = var.website == null ? [] : [""]

    content {
      main_page_suffix = var.website.main_page_suffix
      not_found_page   = var.website.not_found_page
    }
  }
}

resource "google_storage_bucket_object" "objects" {
  for_each = var.objects_to_upload

  bucket              = google_storage_bucket.bucket.id
  name                = each.value.name
  metadata            = each.value.metadata
  content             = each.value.content
  source              = each.value.source
  cache_control       = each.value.cache_control
  content_disposition = each.value.content_disposition
  content_encoding    = each.value.content_encoding
  content_language    = each.value.content_language
  content_type        = each.value.content_type
  event_based_hold    = each.value.event_based_hold
  temporary_hold      = each.value.temporary_hold
  detect_md5hash      = each.value.detect_md5hash
  storage_class       = each.value.storage_class
  kms_key_name        = each.value.kms_key_name

  dynamic "customer_encryption" {
    for_each = each.value.customer_encryption == null ? [] : [""]

    content {
      encryption_algorithm = each.value.customer_encryption.encryption_algorithm
      encryption_key       = each.value.customer_encryption.encryption_key
    }
  }
}

resource "google_storage_notification" "notification" {
  count          = local.notification ? 1 : 0
  bucket         = google_storage_bucket.bucket.name
  payload_format = var.notification_config.payload_format
  topic = try(
    google_pubsub_topic.topic[0].id, var.notification_config.topic_name
  )
  custom_attributes  = var.notification_config.custom_attributes
  event_types        = var.notification_config.event_types
  object_name_prefix = var.notification_config.object_name_prefix
  depends_on         = [google_pubsub_topic_iam_binding.binding]
}

resource "google_pubsub_topic_iam_binding" "binding" {
  count   = try(var.notification_config.create_topic, null) == true ? 1 : 0
  topic   = google_pubsub_topic.topic[0].id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${var.notification_config.sa_email}"]
}

resource "google_pubsub_topic" "topic" {
  count   = try(var.notification_config.create_topic, null) == true ? 1 : 0
  project = var.project_id
  name    = var.notification_config.topic_name
}

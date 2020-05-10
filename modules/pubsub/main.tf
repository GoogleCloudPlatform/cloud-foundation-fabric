/**
 * Copyright 2020 Google LLC
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
  iam_pairs = var.subscription_iam_roles == null ? [] : flatten([
    for name, roles in var.subscription_iam_roles :
    [for role in roles : { name = name, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.name}-${pair.role}" => pair
  }
  iam_members = (
    var.subscription_iam_members == null ? {} : var.subscription_iam_members
  )
  oidc_config = {
    for k, v in var.push_configs : k => v.oidc_token
  }
  subscriptions = {
    for k, v in var.subscriptions : k => {
      labels  = v.labels != null ? v.labels : var.labels
      options = v.options != null ? v.options : var.defaults
    }
  }
}

resource "google_pubsub_topic" "default" {
  project      = var.project_id
  name         = var.name
  kms_key_name = var.kms_key
  labels       = var.labels

  dynamic message_storage_policy {
    for_each = length(var.regions) > 0 ? [var.regions] : []
    content {
      allowed_persistence_regions = var.regions
    }
  }
}

resource "google_pubsub_topic_iam_binding" "default" {
  for_each = toset(var.iam_roles)
  project  = var.project_id
  topic    = google_pubsub_topic.default.name
  role     = each.value
  members  = lookup(var.iam_members, each.value, [])
}

resource "google_pubsub_subscription" "default" {
  for_each                   = local.subscriptions
  project                    = var.project_id
  name                       = each.key
  topic                      = google_pubsub_topic.default.name
  labels                     = each.value.labels
  ack_deadline_seconds       = each.value.options.ack_deadline_seconds
  message_retention_duration = each.value.options.message_retention_duration
  retain_acked_messages      = each.value.options.retain_acked_messages

  dynamic expiration_policy {
    for_each = each.value.options.expiration_policy_ttl == null ? [] : [""]
    content {
      ttl = each.value.options.expiration_policy_ttl
    }
  }

  dynamic dead_letter_policy {
    for_each = try(var.dead_letter_configs[each.key], null) == null ? [] : [""]
    content {
      dead_letter_topic     = var.dead_letter_configs[each.key].topic
      max_delivery_attempts = var.dead_letter_configs[each.key].max_delivery_attempts
    }
  }

  dynamic push_config {
    for_each = try(var.push_configs[each.key], null) == null ? [] : [""]
    content {
      push_endpoint = var.push_configs[each.key].endpoint
      attributes    = var.push_configs[each.key].attributes
      dynamic oidc_token {
        for_each = (
          local.oidc_config[each.key] == null ? [] : [""]
        )
        content {
          service_account_email = local.oidc_config[each.key].service_account_email
          audience              = local.oidc_config[each.key].audience
        }
      }
    }
  }
}

resource "google_pubsub_subscription_iam_binding" "default" {
  for_each     = local.iam_keypairs
  project      = var.project_id
  subscription = google_pubsub_subscription.default[each.value.name].name
  role         = each.value.role
  members = lookup(
    lookup(local.iam_members, each.value.name, {}), each.value.role, []
  )
}

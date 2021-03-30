/**
 * Copyright 2021 Google LLC
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
  extended_rules = flatten([
    for policy, rules in var.firewall_policies : [
      for rule_name, rule in rules :
      merge(rule, { policy = policy, name = rule_name })
    ]
  ])
  rules_map = {
    for rule in local.extended_rules :
    "${rule.policy}-${rule.name}" => rule
  }
  logging_sinks = coalesce(var.logging_sinks, {})
  sink_type_destination = {
    gcs      = "storage.googleapis.com"
    bigquery = "bigquery.googleapis.com"
    pubsub   = "pubsub.googleapis.com"
    logging  = "logging.googleapis.com"
  }
  sink_bindings = {
    for type in ["gcs", "bigquery", "pubsub", "logging"] :
    type => {
      for name, sink in local.logging_sinks :
      name => sink
      if sink.iam && sink.type == type
    }
  }
  folder = (
    var.folder_create
    ? try(google_folder.folder.0, null)
    : try(data.google_folder.folder.0, null)
  )
}

data "google_folder" "folder" {
  count  = var.folder_create ? 0 : 1
  folder = var.id
}

resource "google_folder" "folder" {
  count        = var.folder_create ? 1 : 0
  display_name = var.name
  parent       = var.parent
}

resource "google_folder_iam_binding" "authoritative" {
  for_each = var.iam
  folder   = local.folder.name
  role     = each.key
  members  = each.value
}

resource "google_folder_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  folder     = local.folder.name
  constraint = each.key

  dynamic "boolean_policy" {
    for_each = each.value == null ? [] : [each.value]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic "restore_policy" {
    for_each = each.value == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_folder_organization_policy" "list" {
  for_each   = var.policy_list
  folder     = local.folder.name
  constraint = each.key

  dynamic "list_policy" {
    for_each = each.value.status == null ? [] : [each.value]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic "allow" {
        for_each = policy.value.status ? [""] : []
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
      dynamic "deny" {
        for_each = policy.value.status ? [] : [""]
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
    }
  }

  dynamic "restore_policy" {
    for_each = each.value.status == null ? [true] : []
    content {
      default = true
    }
  }
}

resource "google_compute_organization_security_policy" "policy" {
  provider = google-beta
  for_each = var.firewall_policies

  display_name = each.key
  parent       = local.folder.id
}

resource "google_compute_organization_security_policy_rule" "rule" {
  provider = google-beta
  for_each = local.rules_map

  policy_id               = google_compute_organization_security_policy.policy[each.value.policy].id
  action                  = each.value.action
  direction               = each.value.direction
  priority                = each.value.priority
  target_resources        = each.value.target_resources
  target_service_accounts = each.value.target_service_accounts
  enable_logging          = each.value.logging
  # preview                 = each.value.preview
  match {
    description = each.value.description
    config {
      src_ip_ranges  = each.value.direction == "INGRESS" ? each.value.ranges : null
      dest_ip_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null
      dynamic "layer4_config" {
        for_each = each.value.ports
        iterator = port
        content {
          ip_protocol = port.key
          ports       = port.value
        }
      }
    }
  }
}

resource "google_compute_organization_security_policy_association" "attachment" {
  provider      = google-beta
  for_each      = var.firewall_policy_attachments
  name          = "${local.folder.id}-${each.key}"
  attachment_id = local.folder.id
  policy_id     = each.value
}

resource "google_logging_folder_sink" "sink" {
  for_each = local.logging_sinks
  name     = each.key
  #description = "${each.key} (Terraform-managed)"
  folder           = local.folder.name
  destination      = "${local.sink_type_destination[each.value.type]}/${each.value.destination}"
  filter           = each.value.filter
  include_children = each.value.include_children

  dynamic "exclusions" {
    for_each = each.value.exclusions
    iterator = exclusion
    content {
      name   = exclusion.key
      filter = exclusion.value
    }
  }
}

resource "google_storage_bucket_iam_binding" "gcs-sinks-binding" {
  for_each = local.sink_bindings["gcs"]
  bucket   = each.value.destination
  role     = "roles/storage.objectCreator"
  members  = [google_logging_folder_sink.sink[each.key].writer_identity]
}

resource "google_bigquery_dataset_iam_binding" "bq-sinks-binding" {
  for_each   = local.sink_bindings["bigquery"]
  project    = split("/", each.value.destination)[1]
  dataset_id = split("/", each.value.destination)[3]
  role       = "roles/bigquery.dataEditor"
  members    = [google_logging_folder_sink.sink[each.key].writer_identity]
}

resource "google_pubsub_topic_iam_binding" "pubsub-sinks-binding" {
  for_each = local.sink_bindings["pubsub"]
  project  = split("/", each.value.destination)[1]
  topic    = split("/", each.value.destination)[3]
  role     = "roles/pubsub.publisher"
  members  = [google_logging_folder_sink.sink[each.key].writer_identity]
}

resource "google_logging_folder_exclusion" "logging-exclusion" {
  for_each    = coalesce(var.logging_exclusions, {})
  name        = each.key
  folder      = local.folder.name
  description = "${each.key} (Terraform-managed)"
  filter      = each.value
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = local.folder.name
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
}

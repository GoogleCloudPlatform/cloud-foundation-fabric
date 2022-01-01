/**
 * Copyright 2022 Google LLC
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
  group_iam_roles = distinct(flatten(values(var.group_iam)))
  group_iam = {
    for r in local.group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local.group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local.group_iam[role], [])
    )
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
  for_each = local.iam
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

  depends_on = [
    google_folder_iam_binding.authoritative
  ]
}

resource "google_storage_bucket_iam_member" "gcs-sinks-binding" {
  for_each = local.sink_bindings["gcs"]
  bucket   = each.value.destination
  role     = "roles/storage.objectCreator"
  member   = google_logging_folder_sink.sink[each.key].writer_identity
}

resource "google_bigquery_dataset_iam_member" "bq-sinks-binding" {
  for_each   = local.sink_bindings["bigquery"]
  project    = split("/", each.value.destination)[1]
  dataset_id = split("/", each.value.destination)[3]
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_folder_sink.sink[each.key].writer_identity
}

resource "google_pubsub_topic_iam_member" "pubsub-sinks-binding" {
  for_each = local.sink_bindings["pubsub"]
  project  = split("/", each.value.destination)[1]
  topic    = split("/", each.value.destination)[3]
  role     = "roles/pubsub.publisher"
  member   = google_logging_folder_sink.sink[each.key].writer_identity
}

resource "google_project_iam_member" "bucket-sinks-binding" {
  for_each = local.sink_bindings["logging"]
  project  = split("/", each.value.destination)[1]
  role     = "roles/logging.bucketWriter"
  member   = google_logging_folder_sink.sink[each.key].writer_identity
  # TODO(jccb): use a condition to limit writer-identity only to this
  # bucket
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

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

# tfdoc:file:description Log sinks and data access logs.

locals {
  logging_sinks = {
    for k, v in var.logging_sinks :
    # expand destination contexts
    k => merge(v,
      v.type != "bigquery" ? {} : {
        destination = lookup(
          local.ctx.bigquery_datasets, v.destination, v.destination
        )
      },
      v.type != "logging" ? {} : {
        destination = lookup(
          local.ctx.log_buckets, v.destination, v.destination
        )
      },
      v.type != "project" ? {} : {
        api         = "logging"
        destination = "projects/${lookup(local.ctx.project_ids, v.destination, v.destination)}"
      },
      v.type != "pubsub" ? {} : {
        destination = lookup(
          local.ctx.pubsub_topics, v.destination, v.destination
        )
      },
      v.type != "storage" ? {} : {
        destination = lookup(
          local.ctx.storage_buckets, v.destination, v.destination
        )
      }
    )
  }
  sink_bindings = {
    for type in ["bigquery", "logging", "project", "pubsub", "storage"] :
    type => {
      for name, sink in local.logging_sinks :
      name => sink if sink.iam && sink.type == type
    }
  }

  logging_bucket_sinks_by_project = {
    for project_id in distinct([
      for name, sink in local.sink_bindings["logging"] : split("/", sink.destination)[1]
    ]) :
    project_id => sort([
      for name, sink in local.sink_bindings["logging"] : name
      if split("/", sink.destination)[1] == project_id
    ])
  }
  # 13 destinations => 12 "||" operators (max allowed).
  logging_bucket_sink_chunks_by_project = {
    for project_id, names in local.logging_bucket_sinks_by_project :
    project_id => chunklist(names, 13)
  }
  logging_bucket_sink_chunks = merge([
    for project_id, chunks in local.logging_bucket_sink_chunks_by_project : {
      for index, names in chunks :
      "${project_id}-${index}" => {
        project_id = project_id
        index      = index + 1
        sink_names = names
      }
    }
  ]...)
}

resource "google_logging_organization_settings" "default" {
  count                = var.logging_settings != null ? 1 : 0
  organization         = local.organization_id_numeric
  disable_default_sink = var.logging_settings.disable_default_sink
  kms_key_name         = var.logging_settings.kms_key_name
  storage_location = lookup(
    local.ctx.locations,
    coalesce(var.logging_settings.storage_location, ""),
    var.logging_settings.storage_location
  )
}

resource "google_organization_iam_audit_config" "default" {
  for_each = var.logging_data_access
  org_id   = local.organization_id_numeric
  service  = each.key
  dynamic "audit_log_config" {
    for_each = { for k, v in each.value : k => v if v != null }
    content {
      log_type = audit_log_config.key
      exempted_members = [
        for m in try(audit_log_config.value.exempted_members, []) :
        lookup(local.ctx.iam_principals, m, m)
      ]
    }
  }
}

resource "google_logging_organization_sink" "sink" {
  for_each           = local.logging_sinks
  name               = each.key
  description        = coalesce(each.value.description, "${each.key} (Terraform-managed).")
  org_id             = local.organization_id_numeric
  destination        = "${lookup(each.value, "api", each.value.type)}.googleapis.com/${each.value.destination}"
  filter             = each.value.filter
  include_children   = each.value.include_children
  intercept_children = each.value.intercept_children
  disabled           = each.value.disabled
  dynamic "bigquery_options" {
    for_each = each.value.type == "bigquery" ? [""] : []
    content {
      use_partitioned_tables = each.value.bq_partitioned_table
    }
  }
  dynamic "exclusions" {
    for_each = each.value.exclusions
    iterator = exclusion
    content {
      name   = exclusion.key
      filter = exclusion.value
    }
  }
  depends_on = [
    google_organization_iam_binding.authoritative,
    google_organization_iam_binding.bindings,
    google_organization_iam_member.bindings
  ]
}

resource "google_storage_bucket_iam_member" "storage-sinks-binding" {
  for_each = local.sink_bindings["storage"]
  bucket   = each.value.destination
  role     = "roles/storage.objectCreator"
  member   = google_logging_organization_sink.sink[each.key].writer_identity
}

resource "google_bigquery_dataset_iam_member" "bq-sinks-binding" {
  for_each   = local.sink_bindings["bigquery"]
  project    = split("/", each.value.destination)[1]
  dataset_id = split("/", each.value.destination)[3]
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.sink[each.key].writer_identity
}

resource "google_pubsub_topic_iam_member" "pubsub-sinks-binding" {
  for_each = local.sink_bindings["pubsub"]
  project  = split("/", each.value.destination)[1]
  topic    = split("/", each.value.destination)[3]
  role     = "roles/pubsub.publisher"
  member   = google_logging_organization_sink.sink[each.key].writer_identity
}

resource "google_project_iam_member" "bucket-sinks-binding" {
  for_each = local.logging_bucket_sink_chunks
  project  = each.value.project_id
  role     = "roles/logging.bucketWriter"

  # Organization sinks typically share a single writer identity.
  # We reference the first sink in the chunk to obtain the principal.
  member = google_logging_organization_sink.sink[each.value.sink_names[0]].writer_identity

  condition {
    title       = "log_bucket_writer_${each.value.index}"
    description = "Grants bucketWriter to ${google_logging_organization_sink.sink[each.value.sink_names[0]].writer_identity} for ${length(each.value.sink_names)} logging bucket(s) (chunk ${each.value.index}) on ${var.organization_id}."
    expression = join(" || ", [
      for name in each.value.sink_names :
      "resource.name.endsWith('${local.sink_bindings["logging"][name].destination}')"
    ])
  }
}

resource "google_project_iam_member" "project-sinks-binding" {
  for_each = local.sink_bindings["project"]
  project  = each.value.destination
  role     = "roles/logging.logWriter"
  member   = google_logging_organization_sink.sink[each.key].writer_identity
}

resource "google_logging_organization_exclusion" "logging-exclusion" {
  for_each    = var.logging_exclusions
  name        = each.key
  org_id      = local.organization_id_numeric
  description = "${each.key} (Terraform-managed)."
  filter      = each.value
}

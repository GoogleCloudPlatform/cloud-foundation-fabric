/**
 * Copyright 2019 Google LLC
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
  access_list = flatten([
    for role, accesses in var.access : [
      for access in accesses : merge(access, { role = role })
    ]
  ])
  access_default = {
    for access in local.access_list :
    "${access.role}-${access.identity_type}-${access.identity}" => access
  }
  access_views = {
    for access in var.access_views :
    "${access.project_id}-${access.dataset_id}-${access.table_id}" => access
  }
}

resource "google_bigquery_dataset" "default" {
  project       = var.project_id
  dataset_id    = var.id
  friendly_name = var.friendly_name
  description   = "Terraform managed."
  labels        = var.labels
  location      = var.location

  delete_contents_on_destroy      = var.options.delete_contents_on_destroy
  default_table_expiration_ms     = var.options.default_table_expiration_ms
  default_partition_expiration_ms = var.options.default_partition_expiration_ms

  dynamic access {
    for_each = var.access_authoritative ? local.access_default : {}
    content {
      role = access.value.role
      domain = (
        access.value.identity_type == "domain" ? access.value.identity : null
      )
      group_by_email = (
        access.value.identity_type == "group_by_email" ? access.value.identity : null
      )
      special_group = (
        access.value.identity_type == "special_group" ? access.value.identity : null
      )
      user_by_email = (
        access.value.identity_type == "user_by_email" ? access.value.identity : null
      )
    }
  }

  dynamic access {
    for_each = var.access_authoritative ? local.access_views : {}
    content {
      view {
        project_id = access.value.project_id
        dataset_id = access.value.dataset_id
        table_id   = access.value.table_id
      }
    }
  }

  dynamic default_encryption_configuration {
    for_each = var.encryption_key == null ? [] : [""]
    content {
      kms_key_name = var.encryption_key
    }
  }
}


resource "google_bigquery_dataset_access" "default" {
  for_each   = var.access_authoritative ? {} : local.access_default
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  role       = each.value.role
  domain = (
    each.value.identity_type == "domain" ? each.value.identity : null
  )
  group_by_email = (
    each.value.identity_type == "group_by_email" ? each.value.identity : null
  )
  special_group = (
    each.value.identity_type == "special_group" ? each.value.identity : null
  )
  user_by_email = (
    each.value.identity_type == "user_by_email" ? each.value.identity : null
  )
}


resource "google_bigquery_dataset_access" "views" {
  for_each   = var.access_authoritative ? {} : local.access_views
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  view {
    project_id = each.value.project
    dataset_id = each.value.dataset_id
    table_id   = each.value.table_id
  }
}

resource "google_bigquery_table" "default" {
  provider        = google-beta
  for_each        = var.tables
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.default.dataset_id
  table_id        = each.key
  friendly_name   = each.value.friendly_name
  description     = "Terraform managed."
  clustering      = try(each.value.options.clustering, null)
  expiration_time = try(each.value.options.expiration_time, null)
  labels          = each.value.labels
  schema          = each.value.schema

  dynamic encryption_configuration {
    for_each = try(each.value.options.encryption_key, null) != null ? [""] : []
    content {
      kms_key_name = each.value.options.encryption_key
    }
  }

  dynamic range_partitioning {
    for_each = try(each.value.partitioning.range, null) != null ? [""] : []
    content {
      field = each.value.partitioning.field
      range {
        start    = each.value.partitioning.range.start
        end      = each.value.partitioning.range.end
        interval = each.value.partitioning.range.interval
      }
    }
  }

  dynamic time_partitioning {
    for_each = try(each.value.partitioning.time, null) != null ? [""] : []
    content {
      expiration_ms = each.value.partitioning.time.expiration_ms
      field         = each.value.partitioning.field
      type          = each.value.partitioning.time.type
    }
  }

}


resource "google_bigquery_table" "views" {
  for_each      = var.views
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.default.dataset_id
  table_id      = each.key
  friendly_name = each.value.friendly_name
  description   = "Terraform managed."
  labels        = each.value.labels

  view {
    query          = each.value.query
    use_legacy_sql = each.value.use_legacy_sql
  }

}

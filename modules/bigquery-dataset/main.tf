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
  access_domain = {
    for k, v in var.access_roles : k => v if v.type == "domain"
  }
  access_group = {
    for k, v in var.access_roles : k => v if v.type == "group_by_email"
  }
  access_special = {
    for k, v in var.access_roles : k => v if v.type == "special_group"
  }
  access_user = {
    for k, v in var.access_roles : k => v if v.type == "user_by_email"
  }
  access_view = {
    for k, v in var.access_roles : k => v if v.type == "view"
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
    for_each = var.dataset_access ? local.access_domain : {}
    content {
      role   = access.value.role
      domain = try(var.access_identities[access.key])
    }
  }

  dynamic access {
    for_each = var.dataset_access ? local.access_group : {}
    content {
      role           = access.value.role
      group_by_email = try(var.access_identities[access.key])
    }
  }

  dynamic access {
    for_each = var.dataset_access ? local.access_special : {}
    content {
      role          = access.value.role
      special_group = try(var.access_identities[access.key])
    }
  }

  dynamic access {
    for_each = var.dataset_access ? local.access_user : {}
    content {
      role          = access.value.role
      user_by_email = try(var.access_identities[access.key])
    }
  }

  dynamic access {
    for_each = var.dataset_access ? local.access_view : {}
    content {
      view {
        project_id = try(var.access.views[access.key].project_id, null)
        dataset_id = try(var.access.views[access.key].dataset_id, null)
        table_id   = try(var.access.views[access.key].table_id, null)
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


resource "google_bigquery_dataset_access" "domain" {
  for_each   = var.dataset_access ? {} : local.access_domain
  provider   = google-beta
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  role       = each.value.role
  domain     = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "group_by_email" {
  for_each       = var.dataset_access ? {} : local.access_group
  provider       = google-beta
  project        = var.project_id
  dataset_id     = google_bigquery_dataset.default.dataset_id
  role           = each.value.role
  group_by_email = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "special_group" {
  for_each      = var.dataset_access ? {} : local.access_special
  provider      = google-beta
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.default.dataset_id
  role          = each.value.role
  special_group = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "user_by_email" {
  for_each      = var.dataset_access ? {} : local.access_user
  provider      = google-beta
  project       = var.project_id
  dataset_id    = google_bigquery_dataset.default.dataset_id
  role          = each.value.role
  user_by_email = try(var.access_identities[each.key])
}

resource "google_bigquery_dataset_access" "views" {
  for_each   = var.dataset_access ? {} : local.access_view
  provider   = google-beta
  project    = var.project_id
  dataset_id = google_bigquery_dataset.default.dataset_id
  view {
    project_id = try(var.access_views[each.key].project_id, null)
    dataset_id = try(var.access_views[each.key].dataset_id, null)
    table_id   = try(var.access_views[each.key].table_id, null)
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
  depends_on    = [google_bigquery_table.default]
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

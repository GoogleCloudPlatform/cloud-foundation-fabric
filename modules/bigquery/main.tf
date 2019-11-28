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

resource "google_bigquery_dataset" "datasets" {
  count                           = length(var.datasets)
  project                         = var.project_id
  dataset_id                      = var.datasets[count.index]["id"]
  friendly_name                   = var.datasets[count.index]["name"]
  description                     = var.datasets[count.index]["description"]
  location                        = var.datasets[count.index]["location"]
  labels                          = lookup(var.datasets[count.index], "labels", null)
  default_table_expiration_ms     = lookup(var.datasets[count.index], "default_table_expiration_ms", null)
  default_partition_expiration_ms = lookup(var.datasets[count.index], "default_partition_expiration_ms", null)

  dynamic "access" {
    for_each = lookup(var.dataset_access, var.datasets[count.index]["id"], tomap({}))
    content {
      user_by_email = access.key
      role          = access.value
    }
  }

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
}

resource "google_bigquery_table" "tables" {
  count           = length(var.tables)
  project         = var.project_id
  dataset_id      = var.tables[count.index]["dataset_id"]
  table_id        = var.tables[count.index]["table_id"]
  labels          = var.tables[count.index]["labels"]
  expiration_time = lookup(var.tables[count.index], "expiration_time", null)
  clustering      = lookup(var.tables[count.index], "clustering", null)
  schema          = jsonencode(var.tables[count.index]["schema"])

  dynamic "time_partitioning" {
    for_each = lookup(var.tables[count.index], "time_partitioning", false) == false ? [] : [1]
    content {
      field         = var.tables[count.index]["time_partitioning"]["field"]
      type          = var.tables[count.index]["time_partitioning"]["type"]
      expiration_ms = lookup(var.tables[count.index], "expiration_ms", null)
    }
  }

  depends_on = [google_bigquery_dataset.datasets]
}

resource "google_bigquery_table" "views" {
  count      = length(var.views)
  project    = var.project_id
  dataset_id = var.views[count.index]["dataset"]
  table_id   = var.views[count.index]["table"]
  view {
    query          = var.views[count.index]["query"]
    use_legacy_sql = false
  }
  depends_on = [google_bigquery_table.tables]
}

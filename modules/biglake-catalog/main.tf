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
  tables = merge([
    for k1, v1 in var.databases : {
      for k2, v2 in v1.tables : "${k1}-${k2}" => merge({
        database_name = k1
        table_name    = k2
      }, v2)
    }
  ]...)
}

resource "google_biglake_catalog" "catalog" {
  name     = var.name
  location = var.location
  project  = var.project_id
}

resource "google_biglake_database" "databases" {
  for_each = var.databases
  name     = each.key
  catalog  = google_biglake_catalog.catalog.id
  type     = each.value.type
  hive_options {
    location_uri = each.value.hive_options.location_uri
    parameters   = each.value.hive_options.parameters
  }
}

resource "google_biglake_table" "tables" {
  for_each = local.tables
  name     = each.value.table_name
  database = google_biglake_database.databases[each.value.database_name].id
  type     = each.value.type
  hive_options {
    table_type = each.value.hive_options.table_type
    storage_descriptor {
      location_uri  = each.value.hive_options.location_uri
      input_format  = each.value.hive_options.input_format
      output_format = each.value.hive_options.output_format
    }
    # Some Example Parameters.
    parameters = each.value.hive_options.parameters
  }
}
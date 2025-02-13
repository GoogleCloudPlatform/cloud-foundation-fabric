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

output "catalog" {
  description = "Catalog."
  value       = google_biglake_catalog.catalog
}

output "catalog_id" {
  description = "Catalog ID."
  value       = google_biglake_catalog.catalog.id
}

output "database_ids" {
  description = "Database IDs."
  value       = { for k, v in google_biglake_database.databases : k => v.id }
}

output "databases" {
  description = "Databases."
  value       = google_biglake_database.databases
}

output "table_ids" {
  description = "Table ids."
  value       = { for k, v in google_biglake_table.tables : k => v.id }
}

output "tables" {
  description = "Tables."
  value       = google_biglake_table.tables
}



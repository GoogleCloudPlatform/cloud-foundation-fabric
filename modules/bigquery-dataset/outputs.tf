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

output "dataset" {
  description = "Dataset resource."
  value       = google_bigquery_dataset.default
}

output "dataset_id" {
  description = "Dataset full id."
  value       = google_bigquery_dataset.default.dataset_id
}

output "id" {
  description = "Dataset id."
  value       = google_bigquery_dataset.default.id
}

output "self_link" {
  description = "Dataset self link."
  value       = google_bigquery_dataset.default.self_link
}

output "tables" {
  description = "Table resources."
  value       = google_bigquery_table.default
}

output "views" {
  description = "View resources."
  value       = google_bigquery_table.views
}

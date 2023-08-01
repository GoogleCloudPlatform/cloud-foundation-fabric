/**
 * Copyright 2023 Google LLC
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

output "data_scan_id" {
  description = "Dataplex DataScan ID."
  value       = google_dataplex_datascan.datascan.data_scan_id
}

output "id" {
  description = "A fully qualified Dataplex DataScan identifier for the resource with format projects/{{project}}/locations/{{location}}/dataScans/{{data_scan_id}}."
  value       = google_dataplex_datascan.datascan.id
}

output "name" {
  description = "The relative resource name of the scan, of the form: projects/{project}/locations/{locationId}/dataScans/{datascan_id}, where project refers to a project_id or project_number and locationId refers to a GCP region."
  value       = google_dataplex_datascan.datascan.name
}

output "type" {
  description = "The type of DataScan."
  value       = google_dataplex_datascan.datascan.type
}

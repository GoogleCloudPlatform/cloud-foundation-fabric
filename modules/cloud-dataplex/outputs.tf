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

output "assets" {
  description = "Assets attached to the lake of Dataplex Lake."
  value       = local.zone_assets[*]
}

output "id" {
  description = "Fully qualified Dataplex Lake id."
  value       = google_dataplex_lake.lake.id
}

output "lake" {
  description = "The lake name of Dataplex Lake."
  value       = google_dataplex_lake.lake.name
}

output "zones" {
  description = "The zone name of Dataplex Lake."
  value       = distinct(local.zone_assets[*]["zone_name"])
}


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

data "google_project" "project" {
  count      = var.project_number == null ? 1 : 0
  project_id = var.project_id
}

resource "google_tags_location_tag_binding" "primary_binding" {
  for_each = var.tag_bindings
  parent = (
    "//alloydb.googleapis.com/projects/${coalesce(var.project_number, try(data.google_project.project[0].number, null))}/locations/${var.location}/clusters/${google_alloydb_cluster.primary.cluster_id}"
  )
  tag_value = each.value
  location  = var.location
}

resource "google_tags_location_tag_binding" "secondary_binding" {
  for_each = var.cross_region_replication.enabled ? var.tag_bindings : {}
  parent = (
    "//alloydb.googleapis.com/projects/${coalesce(var.project_number, try(data.google_project.project[0].number, null))}/locations/${var.cross_region_replication.region}/clusters/${google_alloydb_cluster.secondary[0].cluster_id}"
  )
  tag_value = each.value
  location  = var.cross_region_replication.region
}

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

resource "google_tags_location_tag_binding" "subnet" {
  for_each  = var.tag_bindings
  parent    = "//compute.googleapis.com/projects/${local.project_id}/regions/${var.region}/subnetworks/${data.google_compute_subnetwork.subnet.subnetwork_id}"
  //compute.googleapis.com/projects/tudev-tudev-networking-dev-0/regions/us-central1/subnetworks/6209686697692724730
  tag_value = lookup(local.ctx.tag_values, each.value, each.value)
  location  = var.region
  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

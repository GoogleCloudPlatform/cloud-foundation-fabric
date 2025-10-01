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

resource "google_tags_tag_binding" "vpc" {
  provider = google-beta
  
  for_each  = var.tag_bindings
  parent    = "//compute.googleapis.com/projects/${local.project_number}/global/networks/${google_compute_network.network[0].numeric_id}"
  tag_value = lookup(local.ctx.tag_values, each.value, each.value)
  depends_on = [
    google_compute_network.network
  ]
}

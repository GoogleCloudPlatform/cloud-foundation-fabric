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

resource "google_tags_location_tag_binding" "binding" {
  for_each = var.tag_bindings
  parent = (
    "//run.googleapis.com/projects/${var.project_id}/locations/europe-west1/services/${google_cloud_run_service.service.name}"
  )
  tag_value = each.value
  location  = var.region
}

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

resource "google_clouddeploy_delivery_pipeline_iam_binding" "default" {
  project    = var.project_id
  location   = var.region
  for_each   = var.iam
  name       = var.name
  role       = each.key
  members    = each.value
  depends_on = [google_clouddeploy_delivery_pipeline.pipeline]
}

resource "google_clouddeploy_target_iam_binding" "default" {
  for_each = local.target_iam_attributes

  project    = each.value.project_id
  location   = each.value.region
  name       = each.value.target_id
  role       = each.value.role
  members    = each.value.members
  depends_on = [google_clouddeploy_target.target]
}

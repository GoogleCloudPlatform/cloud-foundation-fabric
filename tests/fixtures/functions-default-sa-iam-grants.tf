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

resource "google_project_iam_member" "bucket_default_compute_account_grant" {
  project    = var.project_id
  member     = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  role       = "roles/storage.objectViewer"
  depends_on = [google_project_iam_member.artifact_writer]
}

resource "google_project_iam_member" "artifact_writer" {
  project = var.project_id
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  role    = "roles/artifactregistry.createOnPushWriter"
}

/**
 * Copyright 2021 Google LLC
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

resource "google_sourcerepo_repository" "default" {
  project = var.project_id
  name    = var.name
}

resource "google_sourcerepo_repository_iam_binding" "default" {
  for_each   = var.iam
  project    = var.project_id
  repository = google_sourcerepo_repository.default.name
  role       = each.key
  members    = each.value

  depends_on = [
    google_sourcerepo_repository.default
  ]
}

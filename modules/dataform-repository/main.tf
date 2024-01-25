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

resource "google_dataform_repository" "default" {
  provider        = google-beta
  project         = var.project_id
  name            = var.name
  region          = var.region
  service_account = var.service_account

  dynamic "git_remote_settings" {
    for_each = var.remote_repository_settings != null ? [1] : []
    content {
      url                                 = var.remote_repository_settings.url
      default_branch                      = var.remote_repository_settings.branch
      authentication_token_secret_version = var.remote_repository_settings.secret_version
    }
  }
}

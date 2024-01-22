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

resource "google_secret_manager_secret" "secret" {
  count     = var.dataform_remote_repository_url != "" ? 1 : 0
  provider  = google-beta
  project   = var.project_id
  secret_id = var.dataform_secret_name

  replication {
    auto {
    }
  }
}

resource "google_secret_manager_secret_version" "secret_version" {
  count    = var.dataform_remote_repository_url != "" ? 1 : 0
  provider = google-beta
  secret   = google_secret_manager_secret.secret[0].id

  secret_data = var.dataform_remote_repository_token
  depends_on  = [google_secret_manager_secret.secret]
}

resource "google_dataform_repository" "dataform_repository" {
  provider        = google-beta
  project         = var.project_id
  name            = var.dataform_repository_name
  region          = var.region
  service_account = var.dataform_service_account

  dynamic "git_remote_settings" {
    for_each = var.dataform_remote_repository_url != "" ? [1] : []
    content {
      url                                 = var.dataform_remote_repository_url
      default_branch                      = var.dataform_remote_repository_branch
      authentication_token_secret_version = google_secret_manager_secret_version.secret_version[0].id
    }
  }
  depends_on = [google_secret_manager_secret_version.secret_version]
}

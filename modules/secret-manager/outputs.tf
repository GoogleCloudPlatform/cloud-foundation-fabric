/**
 * Copyright 2022 Google LLC
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

output "ids" {
  description = "Fully qualified secret ids."
  value = {
    for k, v in google_secret_manager_secret.default : v.secret_id => v.id
  }
  depends_on = [
    google_secret_manager_secret_iam_binding.default
  ]
}

output "secrets" {
  description = "Secret resources."
  value       = google_secret_manager_secret.default
  depends_on = [
    google_secret_manager_secret_iam_binding.default
  ]

}

output "version_ids" {
  description = "Version ids keyed by secret name : version name."
  value = {
    for k, v in google_secret_manager_secret_version.default : k => v.id
  }
  depends_on = [
    google_secret_manager_secret_iam_binding.default
  ]
}

output "version_versions" {
  description = "Version versions keyed by secret name : version name."
  value = {
    for k, v in google_secret_manager_secret_version.default : k => v.version
  }
  depends_on = [
    google_secret_manager_secret_iam_binding.default
  ]
}

output "versions" {
  description = "Secret versions."
  value       = google_secret_manager_secret_version.default
  sensitive   = true
  depends_on = [
    google_secret_manager_secret_iam_binding.default
  ]
}

/**
 * Copyright 2020 Google LLC
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

output "folder" {
  description = "Folder resource."
  value       = google_folder.folder
}

output "id" {
  description = "Folder id."
  value       = google_folder.folder.name
  depends_on = [
    google_folder_iam_binding.authoritative,
    google_folder_organization_policy.boolean,
    google_folder_organization_policy.list
  ]
}

output "name" {
  description = "Folder name."
  value       = google_folder.folder.display_name
}

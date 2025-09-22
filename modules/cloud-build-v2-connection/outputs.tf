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

output "id" {
  description = "Connection id."
  value = (var.connection_create ?
    google_cloudbuildv2_connection.connection[0].id :
  "projects/${local.project_id}/locations/${var.location}/connections/${local.name}")
}

output "repositories" {
  description = "Repositories."
  value       = google_cloudbuildv2_repository.repositories
}

output "repository_ids" {
  description = "Repository ids."
  value       = { for k, v in google_cloudbuildv2_repository.repositories : k => v.id }
}

output "trigger_ids" {
  description = "Trigger ids."
  value       = { for k, v in google_cloudbuild_trigger.triggers : k => v.id }
}

output "triggers" {
  description = "Triggers."
  value       = google_cloudbuild_trigger.triggers
}

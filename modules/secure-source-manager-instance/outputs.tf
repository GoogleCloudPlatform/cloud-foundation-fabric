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

output "http_service_attachment" {
  description = "PSC service attachment for the instance HTTP endpoint."
  value = try(
    google_secure_source_manager_instance.instance[0].private_config[0].http_service_attachment,
    null
  )
}

output "instance" {
  description = "Instance."
  value       = try(google_secure_source_manager_instance.instance[0], null)
}

output "instance_id" {
  description = "Instance id."
  value       = try(google_secure_source_manager_instance.instance[0].id, null)
}

output "repositories" {
  description = "Repositories."
  value       = google_secure_source_manager_repository.repositories
}

output "repository_ids" {
  description = "Repository ids."
  value       = { for k, v in google_secure_source_manager_repository.repositories : k => v.id }
}

output "ssh_service_attachment" {
  description = "PSC service attachment for the instance SSH endpoint."
  value = try(
    google_secure_source_manager_instance.instance[0].private_config[0].ssh_service_attachment,
    null
  )
}

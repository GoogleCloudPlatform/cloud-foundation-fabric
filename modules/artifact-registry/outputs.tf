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

output "id" {
  description = "Fully qualified repository id."
  value       = google_artifact_registry_repository.registry.id
  depends_on = [
    google_artifact_registry_repository_iam_binding.authoritative,
    google_artifact_registry_repository_iam_binding.bindings2,
    google_artifact_registry_repository_iam_member.members,
  ]
}

output "name" {
  description = "Repository name."
  value       = google_artifact_registry_repository.registry.name
}

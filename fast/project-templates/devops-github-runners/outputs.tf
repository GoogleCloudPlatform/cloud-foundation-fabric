/**
 * Copyright 2026 Google LLC
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

output "crema_config_parameter_version" {
  description = "Active Regional Parameter Manager version ID for CREMA configuration."
  value       = google_parameter_manager_regional_parameter_version.crema_config.id
}

output "crema_service_id" {
  description = "ID of the CREMA Cloud Run autoscaler service."
  value       = module.crema-autoscaler.id
}

output "github_app_private_key_secret_id" {
  description = "Secret Manager secret ID for the GitHub App private key."
  value       = module.secrets.secrets["github-app-private-key"].secret_id
}

output "runner_image_uri" {
  description = "Full Artifact Registry image URI for the GitHub Actions runner."
  value       = local.runner_image_uri
}

output "worker_pool_id" {
  description = "ID of the Cloud Run Worker Pool."
  value       = module.worker-pool.id
}

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

output "bucket" {
  description = "Cloud Function deployment bucket resource."
  value       = local.function.bucket
}

output "project_id" {
  description = "Project id."
  value       = module.project.project_id
}

output "service_account" {
  description = "Cloud Function service account."
  value = {
    email     = local.function.service_account_email
    iam_email = local.function.service_account_iam_email
  }
}

output "troubleshooting_payload" {
  description = "Cloud Function payload used for manual triggering."
  sensitive   = true
  value = jsonencode({
    data = var.cloud_function_config.version == "v1" ? google_cloud_scheduler_job.default[0].pubsub_target.0.data : google_cloud_scheduler_job.scheduler-http[0].http_target.0.body
  })
}

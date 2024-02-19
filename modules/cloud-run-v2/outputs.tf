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

output "id" {
  description = "Fully qualified job or service id."
  value       = var.create_job ? google_cloud_run_v2_job.job[0].id : google_cloud_run_v2_service.service[0].id
}

output "job" {
  description = "Cloud Run Job."
  value       = var.create_job ? google_cloud_run_v2_job.job[0] : null
}

output "service" {
  description = "Cloud Run Service."
  value       = var.create_job ? null : google_cloud_run_v2_service.service[0]
}

output "service_account" {
  description = "Service account resource."
  value       = try(google_service_account.service_account[0], null)
}

output "service_account_email" {
  description = "Service account email."
  value       = local.service_account_email
}

output "service_account_iam_email" {
  description = "Service account email."
  value = join("", [
    "serviceAccount:",
    local.service_account_email == null ? "" : local.service_account_email
  ])
}

output "service_name" {
  description = "Cloud Run service name."
  value       = var.create_job ? null : google_cloud_run_v2_service.service[0].name
}

output "vpc_connector" {
  description = "VPC connector resource if created."
  value       = try(google_vpc_access_connector.connector.0.id, null)
}

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
  description = "Fully qualified job or service id."
  value       = local.resource.id
}

output "invoke_command" {
  description = "Command to invoke Cloud Run Service / submit job."
  value       = local.invoke_command
}

output "job" {
  description = "Cloud Run Job."
  value       = var.type == "JOB" ? local._resource[var.type] : null
}

output "resource" {
  description = "Cloud Run resource (job, service or worker_pool)."
  value       = local._resource[var.type]
}

output "resource_name" {
  description = "Cloud Run resource (job, service or workerpool)  service name."
  value       = local.resource.name
}

output "service" {
  description = "Cloud Run Service."
  value       = var.type == "SERVICE" ? local._resource[var.type] : null
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
  value       = var.type == "SERVICE" ? local.resource.name : null
}

output "service_uri" {
  description = "Main URI in which the service is serving traffic."
  value       = local.resource.uri
}

output "vpc_connector" {
  description = "VPC connector resource if created."
  value       = try(google_vpc_access_connector.connector[0].id, null)
}

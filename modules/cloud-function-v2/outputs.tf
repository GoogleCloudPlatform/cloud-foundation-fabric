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

output "bucket" {
  description = "Bucket resource (only if auto-created)."
  value = try(
    var.bucket_config == null ? null : google_storage_bucket.bucket[0], null
  )
}

output "bucket_name" {
  description = "Bucket name."
  value       = local.bucket
}

output "function" {
  description = "Cloud function resources."
  value       = google_cloud_run_v2_service.function
}

output "function_name" {
  description = "Cloud Run Function name."
  value       = google_cloud_run_v2_service.function.build_config[0].function_target
}

output "id" {
  description = "Cloud Run Function id."
  value       = google_cloud_run_v2_service.function.id
}

output "invoke_command" {
  description = "Command to invoke Cloud Run Function."
  value       = var.eventarc_triggers != null ? null : <<-EOT
    curl -H "Authorization: bearer $(gcloud auth print-identity-token)" \
        ${google_cloud_run_v2_service.function.urls[0]} \
        -X POST -d 'data'
  EOT
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

output "trigger_service_account" {
  description = "Service account resource."
  value       = try(google_service_account.trigger_service_account[0], null)
}

output "trigger_service_account_email" {
  description = "Service account email."
  value       = local.trigger_sa_email
}

output "trigger_service_account_iam_email" {
  description = "Service account email."
  value = join("", [
    "serviceAccount:",
    local.trigger_sa_email == null ? "" : local.trigger_sa_email
  ])
}

output "uri" {
  description = "Cloud function service uri."
  value       = google_cloud_run_v2_service.function.urls[0]
}

output "vpc_access" {
  description = "VPC access configuration."
  value = {
    egress        = var.vpc_access.egress
    subnet        = var.vpc_access.subnet
    vpc_connector = try(google_vpc_access_connector.connector[0].id, null)
  }
}

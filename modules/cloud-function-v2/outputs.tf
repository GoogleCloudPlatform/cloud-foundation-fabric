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
  description = "Bucket resource (only if auto-created)."
  value = try(
    var.bucket_config == null ? null : google_storage_bucket.bucket.0, null
  )
}

output "bucket_name" {
  description = "Bucket name."
  value       = local.bucket
}

output "function" {
  description = "Cloud function resources."
  value       = google_cloudfunctions2_function.function
}

output "function_name" {
  description = "Cloud function name."
  value       = google_cloudfunctions2_function.function.name
}

output "id" {
  description = "Fully qualified function id."
  value       = google_cloudfunctions2_function.function.id
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
  value       = google_cloudfunctions2_function.function.service_config[0].uri
}

output "vpc_connector" {
  description = "VPC connector resource if created."
  value       = try(google_vpc_access_connector.connector.0.id, null)
}

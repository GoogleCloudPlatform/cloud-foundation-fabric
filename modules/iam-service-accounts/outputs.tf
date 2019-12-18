/**
 * Copyright 2019 Google LLC
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

output "service_account" {
  description = "Service account resource (for single use)."
  value       = local.resource
}

output "service_accounts" {
  description = "Service account resources."
  value       = local.resources
}

output "email" {
  description = "Service account email (for single use)."
  value       = local.resource == null ? null : local.resource.email
}

output "iam_email" {
  description = "IAM-format service account email (for single use)."
  value       = local.resource == null ? null : "serviceAccount:${local.resource.email}"
}

output "key" {
  description = "Service account key (for single use)."
  value       = lookup(local.keys, var.names[0], null)
}

output "emails" {
  description = "Service account emails."
  value       = { for name, resource in local.resources : name => resource.email }
}

output "iam_emails" {
  description = "IAM-format service account emails."
  value       = local.resource_iam_emails
}

output "emails_list" {
  description = "Service account emails."
  value       = [for name, resource in local.resources : resource.email]
}

output "iam_emails_list" {
  description = "IAM-format service account emails."
  value       = [for name, resource in local.resources : "serviceAccount:${resource.email}"]
}

output "keys" {
  description = "Map of service account keys."
  sensitive   = true
  value       = local.keys
}

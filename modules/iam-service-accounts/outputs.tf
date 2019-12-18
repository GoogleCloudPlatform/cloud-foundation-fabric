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
  value       = local.resource.email
}

output "iam_email" {
  description = "IAM-format service account email (for single use)."
  value       = "serviceAccount:${local.resource.email}"
}

output "key" {
  description = "Service account key (for single use)."
  value       = data.template_file.keys[0].rendered
}

output "emails" {
  description = "Service account emails."
  value       = zipmap(var.names, slice(local.emails, 0, length(var.names)))
}

output "iam_emails" {
  description = "IAM-format service account emails."
  value       = zipmap(var.names, slice(local.iam_emails, 0, length(var.names)))
}

output "emails_list" {
  description = "Service account emails."
  value       = local.emails
}

output "iam_emails_list" {
  description = "IAM-format service account emails."
  value       = local.iam_emails
}

data "template_file" "keys" {
  count    = length(var.names)
  template = "$${key}"

  vars = {
    key = var.generate_keys ? base64decode(google_service_account_key.keys[count.index].private_key) : ""
  }
}

output "keys" {
  description = "Map of service account keys."
  sensitive   = true
  value = zipmap(
    var.names,
    slice(data.template_file.keys[*].rendered, 0, length(var.names))
  )
}

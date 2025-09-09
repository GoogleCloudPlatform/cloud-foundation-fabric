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

output "email" {
  description = "Service account email."
  value       = local.static_email
  depends_on = [
    local.service_account
  ]
}

output "iam_email" {
  description = "IAM-format service account email."
  value       = local.static_iam_email
  depends_on = [
    local.service_account
  ]
}

output "id" {
  description = "Fully qualified service account id."
  value       = local.static_id
  depends_on = [
    local.service_account
  ]
}

output "name" {
  description = "Service account name."
  value       = local.static_id
  depends_on = [
    local.service_account
  ]
}

output "service_account" {
  description = "Service account resource."
  value       = local.service_account
}

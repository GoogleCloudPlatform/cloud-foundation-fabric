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

locals {
  o_secrets = merge(
    google_secret_manager_secret.default,
    google_secret_manager_regional_secret.default
  )
  o_versions = merge(
    google_secret_manager_secret_version.default,
    google_secret_manager_regional_secret_version.default
  )
}

output "ids" {
  description = "Fully qualified secret ids."
  value       = { for k, v in local.o_secrets : k => v.id }
  depends_on = [
    google_secret_manager_secret_iam_binding.authoritative,
    google_secret_manager_secret_iam_binding.bindings,
    google_secret_manager_secret_iam_member.members,
    google_secret_manager_regional_secret_iam_binding.authoritative,
    google_secret_manager_regional_secret_iam_binding.bindings,
    google_secret_manager_regional_secret_iam_member.members
  ]
}

output "secrets" {
  description = "Secret resources."
  value       = local.o_secrets
  depends_on = [
    google_secret_manager_secret_iam_binding.authoritative,
    google_secret_manager_secret_iam_binding.bindings,
    google_secret_manager_secret_iam_member.members,
    google_secret_manager_regional_secret_iam_binding.authoritative,
    google_secret_manager_regional_secret_iam_binding.bindings,
    google_secret_manager_regional_secret_iam_member.members
  ]
}

output "version_ids" {
  description = "Fully qualified version ids."
  value       = { for k, v in local.o_versions : k => v.id }
  depends_on = [
    google_secret_manager_secret_iam_binding.authoritative,
    google_secret_manager_secret_iam_binding.bindings,
    google_secret_manager_secret_iam_member.members,
    google_secret_manager_regional_secret_iam_binding.authoritative,
    google_secret_manager_regional_secret_iam_binding.bindings,
    google_secret_manager_regional_secret_iam_member.members
  ]
}

output "version_versions" {
  description = "Version versions."
  value       = { for k, v in local.o_versions : k => v.version }
  depends_on = [
    google_secret_manager_secret_iam_binding.authoritative,
    google_secret_manager_secret_iam_binding.bindings,
    google_secret_manager_secret_iam_member.members,
    google_secret_manager_regional_secret_iam_binding.authoritative,
    google_secret_manager_regional_secret_iam_binding.bindings,
    google_secret_manager_regional_secret_iam_member.members
  ]
}

output "versions" {
  description = "Version resources."
  value       = local.o_versions
  sensitive   = true
  depends_on = [
    google_secret_manager_secret_iam_binding.authoritative,
    google_secret_manager_secret_iam_binding.bindings,
    google_secret_manager_secret_iam_member.members,
    google_secret_manager_regional_secret_iam_binding.authoritative,
    google_secret_manager_regional_secret_iam_binding.bindings,
    google_secret_manager_regional_secret_iam_member.members
  ]
}

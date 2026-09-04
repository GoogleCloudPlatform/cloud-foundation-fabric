# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "id" {
  description = "The workload identity pool ID."
  value       = google_iam_workload_identity_pool.default.id
  depends_on = [
    google_iam_workload_identity_pool_iam_binding.default,
    google_service_account_iam_member.impersonation
  ]
}

output "name" {
  description = "The resource name of the workload identity pool."
  value       = google_iam_workload_identity_pool.default.name
}

output "pool" {
  description = "The workload identity pool resource."
  value       = google_iam_workload_identity_pool.default
}

output "provider_ids" {
  description = "Map of provider IDs."
  value = {
    for k, v in google_iam_workload_identity_pool_provider.default : k => v.id
  }
}

output "provider_names" {
  description = "Map of provider resource names."
  value = {
    for k, v in google_iam_workload_identity_pool_provider.default :
    k => v.name
  }
}

output "providers" {
  description = "Map of provider resources."
  value       = google_iam_workload_identity_pool_provider.default
}

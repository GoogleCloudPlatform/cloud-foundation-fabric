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


output "pool_name" {
  value       = google_iam_workload_identity_pool.default_pool.name
  description = "Pool name."
}

output "pool_id" {
  value       = google_iam_workload_identity_pool.default_pool.id
  description = "Pool ID."
}

output "pool_state" {
  value       = google_iam_workload_identity_pool.default_pool.state
  description = "Pool State."
}

output "principal" {
  value       = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.default_pool.name}"
  description = "Pool provider principal."
}

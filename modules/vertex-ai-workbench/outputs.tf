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

output "compute_instance_id" {
  description = "The Compute Engine instance ID."
  value = try(
    google_workbench_instance.default.gce_setup[0].compute_instance_id,
    null
  )
}

output "create_time" {
  description = "The time the instance was created."
  value       = google_workbench_instance.default.create_time
}

output "creator" {
  description = "The email address of the user who created this instance."
  value       = google_workbench_instance.default.creator
}

output "id" {
  description = "An identifier for the resource."
  value       = google_workbench_instance.default.id
  depends_on = [
    google_workbench_instance.default,
    google_workbench_instance_iam_binding.default
  ]
}

output "instance" {
  description = "The Workbench instance resource."
  value       = google_workbench_instance.default
}

output "name" {
  description = "The name of the workbench instance."
  value       = google_workbench_instance.default.name
}

output "proxy_uri" {
  description = "The endpoint for accessing the Jupyter notebook."
  value       = google_workbench_instance.default.proxy_uri
}

output "service_account" {
  description = "The service account resource."
  value       = try(google_service_account.service_account[0], null)
}

output "service_account_email" {
  description = "The service account email."
  value       = try(local.service_account.email, null)
}

output "service_account_iam_email" {
  description = "The service account email formatted for IAM bindings."
  value = (
    try(local.service_account.email, null) == null
    ? null
    : "serviceAccount:${local.service_account.email}"
  )
}

output "state" {
  description = "The state of the workbench instance."
  value       = google_workbench_instance.default.state
}

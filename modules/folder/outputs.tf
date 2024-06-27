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

output "assured_workload" {
  description = "Assured Workloads workload resource."
  value       = try(google_assured_workloads_workload.folder[0], null)
}

output "folder" {
  description = "Folder resource."
  value       = try(google_folder.folder[0], null)
}

output "id" {
  description = "Fully qualified folder id."
  value       = local.folder_id
  depends_on = [
    google_folder_iam_binding.authoritative,
    google_folder_iam_binding.bindings,
    google_folder_iam_member.bindings,
    google_org_policy_policy.default,
  ]
}

output "name" {
  description = "Folder name."
  value = (
    var.assured_workload_config == null
    ? try(google_folder.folder[0].display_name, null)
    : try(google_assured_workloads_workload.folder[0].resource_settings[0].display_name, null)
  )
}

output "sink_writer_identities" {
  description = "Writer identities created for each sink."
  value = {
    for name, sink in google_logging_folder_sink.sink :
    name => sink.writer_identity
  }
}

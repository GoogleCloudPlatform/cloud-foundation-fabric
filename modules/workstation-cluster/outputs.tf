/**
 * Copyright 2023 Google LLC
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

output "cluster_hostname" {
  description = "Cluster hostname."
  value       = var.private_cluster_config != null ? google_workstations_workstation_cluster.cluster.private_cluster_config[0].cluster_hostname : null
}

output "id" {
  description = "Workstation cluster id."
  value       = google_workstations_workstation_cluster.cluster.workstation_cluster_id
}

output "service_attachment_uri" {
  description = "Workstation service attachment URI."
  value       = var.private_cluster_config != null ? google_workstations_workstation_cluster.cluster.private_cluster_config[0].service_attachment_uri : null
}

output "workstation_configs" {
  description = "Workstation configurations."
  value       = google_workstations_workstation_config.configs
}

output "workstations" {
  description = "Workstations."
  value       = google_workstations_workstation.workstations
}

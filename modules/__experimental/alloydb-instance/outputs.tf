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

output "cluster" {
  description = "Cluster created."
  value       = resource.google_alloydb_cluster.default.display_name
  sensitive   = true
}

output "cluster_id" {
  description = "ID of the Alloy DB Cluster created."
  value       = google_alloydb_cluster.default.cluster_id
}

output "primary_instance" {
  description = "Primary instance created."
  value       = resource.google_alloydb_instance.primary.display_name
}

output "primary_instance_id" {
  description = "ID of the primary instance created."
  value       = google_alloydb_instance.primary.instance_id
}

output "read_pool_instance_ids" {
  description = "IDs of the read instances created."
  value = [
    for rd, details in google_alloydb_instance.read_pool : details.instance_id
  ]
}

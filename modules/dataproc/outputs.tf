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

# tfdoc:file:description Cloud Dataproc module output.

# FIXME: 2024-03-08: broken in provider
#output "bucket_names" {
#  description = "List of bucket names which have been assigned to the cluster."
#  value       = google_dataproc_cluster.cluster.cluster_config[0].bucket
#}
#
#output "http_ports" {
#  description = "The map of port descriptions to URLs."
#  value       = google_dataproc_cluster.cluster.cluster_config[0].endpoint_config[0].http_ports
#}

output "id" {
  description = "Fully qualified cluster id."
  value       = google_dataproc_cluster.cluster.id
}

# FIXME: 2024-03-08: broken in provider
#output "instance_names" {
#  description = "List of instance names which have been assigned to the cluster."
#  value = {
#    master             = google_dataproc_cluster.cluster.cluster_config[0].master_config[0].instance_names
#    worker             = google_dataproc_cluster.cluster.cluster_config[0].worker_config[0].instance_names
#    preemptible_worker = google_dataproc_cluster.cluster.cluster_config[0].preemptible_worker_config[0].instance_names
#  }
#}

output "name" {
  description = "The name of the cluster."
  value       = google_dataproc_cluster.cluster.name
}


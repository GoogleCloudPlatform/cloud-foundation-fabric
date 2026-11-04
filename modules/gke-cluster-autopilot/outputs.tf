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

output "backup_channel_ids" {
  description = "GKE backup channel ids."
  value = {
    for k, v in google_gke_backup_backup_channel.backup_channel : k => v.id
  }
}

output "backup_plan_ids" {
  description = "GKE backup plan ids."
  value = {
    for k, v in google_gke_backup_backup_plan.backup_plan : k => v.id
  }
  # Ensure cross-project restore plans referencing backup_plan_ids are created
  # after and destroyed before any restore channels in the source project.
  depends_on = [
    google_gke_backup_restore_channel.restore_channel
  ]
}

output "ca_certificate" {
  description = "Public certificate of the cluster (base64-encoded)."
  value = (
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )
  sensitive = true
}

# Deprecated attributes are left out of the cluster resource, as Terraform
# warns when a deprecated value reaches a root module output.

output "cluster" {
  description = "Cluster resource."
  sensitive   = true
  value = merge(
    {
      for attr, value in google_container_cluster.cluster : attr => value
      if !contains(["enterprise_config", "remove_default_node_pool"], attr)
    },
    {
      addons_config = [
        for v in google_container_cluster.cluster.addons_config : {
          for attr, value in v : attr => value
          if attr != "parallelstore_csi_driver_config"
        }
      ]
      binary_authorization = [
        for v in google_container_cluster.cluster.binary_authorization : {
          for attr, value in v : attr => value if attr != "enabled"
        }
      ]
      node_config = [
        for v in google_container_cluster.cluster.node_config : merge(v, {
          sandbox_config = [
            for s in v.sandbox_config : {
              for attr, value in s : attr => value if attr != "sandbox_type"
            }
          ]
        })
      ]
      node_pool = [
        for p in google_container_cluster.cluster.node_pool : merge(p, {
          node_config = [
            for v in p.node_config : merge(v, {
              sandbox_config = [
                for s in v.sandbox_config : {
                  for attr, value in s : attr => value if attr != "sandbox_type"
                }
              ]
            })
          ]
        })
      ]
    }
  )
}

output "dns_endpoint" {
  description = "Control plane DNS endpoint."
  value = try(
    google_container_cluster.cluster.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint,
    null
  )
}

output "endpoint" {
  description = "Cluster endpoint."
  value       = google_container_cluster.cluster.endpoint
}

output "id" {
  description = "Fully qualified cluster ID."
  value       = google_container_cluster.cluster.id
}

output "location" {
  description = "Cluster location."
  value       = google_container_cluster.cluster.location
}

output "master_version" {
  description = "Master version."
  value       = google_container_cluster.cluster.master_version
}

output "name" {
  description = "Cluster name."
  value       = google_container_cluster.cluster.name
}

output "notifications" {
  description = "GKE Pub/Sub notifications topic."
  value       = try(google_pubsub_topic.notifications[0].id, null)
}

output "restore_channel_ids" {
  description = "GKE restore channel ids."
  value = {
    for k, v in google_gke_backup_restore_channel.restore_channel : k => v.id
  }
}

output "restore_plan_ids" {
  description = "GKE restore plan ids."
  value = {
    for k, v in google_gke_backup_restore_plan.restore_plan : k => v.id
  }
}

output "self_link" {
  description = "Cluster self link."
  sensitive   = true
  value       = google_container_cluster.cluster.self_link
}

output "workload_identity_pool" {
  description = "Workload identity pool."
  value       = "${local.project_id}.svc.id.goog"
  depends_on = [
    google_container_cluster.cluster
  ]
}

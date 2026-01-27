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

variable "compute_kms_key" {
  description = "KMS key for Compute Engine."
  type        = string
  default     = null
}
variable "gke_kms_key" {
  description = "KMS key for GKE."
  type        = string
  default     = null
}
variable "project_id" {
  description = "Project ID."
  type        = string
}
variable "region" {
  description = "Region."
  type        = string
  default     = "europe-west1"
}

# variable "clusters" {
#   description = "Clusters configuration. Refer to the gke-cluster module for type details."
#   type = map(object({
#     access_config = optional(object({
#       dns_access = optional(bool, true)
#       ip_access = optional(object({
#         authorized_ranges               = optional(map(string), {})
#         disable_public_endpoint         = optional(bool, true)
#         gcp_public_cidrs_access_enabled = optional(bool, false)
#         private_endpoint_config = optional(object({
#           endpoint_subnetwork = optional(string)
#           global_access       = optional(bool, true)
#         }), {})
#       }))
#       private_nodes = optional(bool, true)
#     }), {})
#     cluster_autoscaling = optional(any)
#     description         = optional(string)
#     enable_addons = optional(any, {
#       horizontal_pod_autoscaling = true, http_load_balancing = true
#     })
#     enable_features = optional(any, {
#       shielded_nodes    = true
#       workload_identity = true
#     })
#     fleet_config = optional(object({
#       register                  = optional(bool, true)
#       configmanagement_template = optional(string)
#     }), {})
#     issue_client_certificate = optional(bool, false)
#     labels                   = optional(map(string))
#     location                 = string
#     logging_config = optional(object({
#       enable_system_logs             = optional(bool, true)
#       enable_workloads_logs          = optional(bool, true)
#       enable_api_server_logs         = optional(bool, false)
#       enable_scheduler_logs          = optional(bool, false)
#       enable_controller_manager_logs = optional(bool, false)
#     }), {})
#     maintenance_config = optional(any, {
#       daily_window_start_time = "03:00"
#       recurring_window        = null
#       maintenance_exclusion   = []
#     })
#     max_pods_per_node  = optional(number, 110)
#     min_master_version = optional(string)
#     monitoring_config = optional(object({
#       enable_system_metrics = optional(bool, true)
#       # (Optional) control plane metrics
#       enable_api_server_metrics         = optional(bool, false)
#       enable_controller_manager_metrics = optional(bool, false)
#       enable_scheduler_metrics          = optional(bool, false)
#       # (Optional) kube state metrics
#       enable_daemonset_metrics   = optional(bool, false)
#       enable_deployment_metrics  = optional(bool, false)
#       enable_hpa_metrics         = optional(bool, false)
#       enable_pod_metrics         = optional(bool, false)
#       enable_statefulset_metrics = optional(bool, false)
#       enable_storage_metrics     = optional(bool, false)
#       # Google Cloud Managed Service for Prometheus
#       enable_managed_prometheus = optional(bool, true)
#     }), {})
#     node_locations  = optional(list(string))
#     release_channel = optional(string)
#     service_account = optional(string)

#     node_config = optional(object({
#       boot_disk_kms_key = optional(string)
#     }))
#   }))
#   default  = {}
#   nullable = false
# }

# variable "nodepools" {
#   description = "Nodepools configuration. Refer to the gke-nodepool module for type details."
#   type = map(map(object({
#     gke_version       = optional(string)
#     k8s_labels        = optional(map(string), {})
#     max_pods_per_node = optional(number)
#     name              = optional(string)
#     node_config = optional(any, {
#       disk_type = "pd-balanced"
#       shielded_instance_config = {
#         enable_integrity_monitoring = true
#         enable_secure_boot          = true
#       }
#     })
#     node_count = optional(map(number), {
#       initial = 1
#     })
#     node_locations  = optional(list(string))
#     nodepool_config = optional(any)
#     network_config = optional(object({
#       enable_private_nodes = optional(bool, true)
#       pod_range = optional(object({
#         cidr   = optional(string)
#         create = optional(bool, false)
#         name   = optional(string)
#       }), {})
#       additional_node_network_configs = optional(list(object({
#         network    = string
#         subnetwork = string
#       })), [])
#       additional_pod_network_configs = optional(list(object({
#         subnetwork          = string
#         secondary_pod_range = string
#         max_pods_per_node   = string
#       })), [])
#     }))
#     reservation_affinity  = optional(any)
#     service_account       = optional(any)
#     sole_tenant_nodegroup = optional(string)
#     tags                  = optional(list(string))
#     taints = optional(map(object({
#       value  = string
#       effect = string
#     })))
#   })))
#   default  = {}
#   nullable = false
# }

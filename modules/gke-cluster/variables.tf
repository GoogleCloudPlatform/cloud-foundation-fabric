/**
 * Copyright 2019 Google LLC
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

variable "addons" {
  description = "Addons enabled in the cluster (true means enabled)."
  type = object({
    horizontal_pod_autoscaling = bool
    http_load_balancing        = bool
    network_policy_config      = bool
    cloudrun_config            = bool
    istio_config = object({
      enabled = bool
      tls     = bool
    })
  })
  default = {
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
    network_policy_config      = false
    cloudrun_config            = false
    istio_config = {
      enabled = false
      tls     = false
    }
  }
}

variable "authenticator_security_group" {
  description = "RBAC security group for Google Groups for GKE, format is gke-security-groups@yourdomain.com."
  type        = string
  default     = null
}

variable "cluster_autoscaling" {
  description = "Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler."
  type = object({
    enabled    = bool
    cpu_min    = number
    cpu_max    = number
    memory_min = number
    memory_max = number
  })
  default = {
    enabled    = false
    cpu_min    = 0
    cpu_max    = 0
    memory_min = 0
    memory_max = 0
  }
}

variable "database_encryption" {
  description = "Enable and configure GKE application-layer secrets encryption."
  type = object({
    enabled  = bool
    state    = string
    key_name = string
  })
  default = {
    enabled  = false
    state    = "DECRYPTED"
    key_name = null
  }
}

variable "default_max_pods_per_node" {
  description = "Maximum number of pods per node in this cluster."
  type        = number
  default     = 110
}

variable "description" {
  description = "Cluster description."
  type        = string
  default     = null
}

variable "enable_binary_authorization" {
  description = "Enable Google Binary Authorization."
  type        = bool
  default     = null
}

variable "enable_intranode_visibility" {
  description = "Enable intra-node visibility to make same node pod to pod traffic visible."
  type        = bool
  default     = null
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded Nodes features on all nodes in this cluster."
  type        = bool
  default     = null
}

variable "enable_tpu" {
  description = "Enable Cloud TPU resources in this cluster."
  type        = bool
  default     = null
}

variable "labels" {
  description = "Cluster resource labels."
  type        = map(string)
  default     = null
}

variable "location" {
  description = "Cluster zone or region."
  type        = string
}

variable "logging_service" {
  description = "Logging service (disable with an empty string)."
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "maintenance_start_time" {
  description = "Maintenance start time in RFC3339 format 'HH:MM', where HH is [00-23] and MM is [00-59] GMT."
  type        = string
  default     = "03:00"
}

variable "master_authorized_ranges" {
  description = "External Ip address ranges that can access the Kubernetes cluster master through HTTPS."
  type        = map(string)
  default     = {}
}

variable "min_master_version" {
  description = "Minimum version of the master, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "monitoring_service" {
  description = "Monitoring service (disable with an empty string)."
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "name" {
  description = "Cluster name."
  type        = string
}

variable "network" {
  description = "Name or self link of the VPC used for the cluster. Use the self link for Shared VPC."
  type        = string
}

variable "node_locations" {
  description = "Zones in which the cluster's nodes are located."
  type        = list(string)
  default     = []
}

variable "pod_security_policy" {
  description = "Enable the PodSecurityPolicy feature."
  type        = bool
  default     = null
}

variable "private_cluster_config" {
  description = "Enable and configure private cluster."
  type = object({
    enable_private_nodes    = bool
    enable_private_endpoint = bool
    master_ipv4_cidr_block  = string
  })
  default = null
}

variable "project_id" {
  description = "Cluster project id."
  type        = string
}

variable "release_channel" {
  description = "Release channel for GKE upgrades."
  type        = string
  default     = null
}

variable "resource_usage_export_config" {
  description = "Configure the ResourceUsageExportConfig feature."
  type = object({
    enabled = bool
    dataset = string
  })
  default = {
    enabled = null
    dataset = null
  }
}

variable "secondary_range_pods" {
  description = "Subnet secondary range name used for pods."
  type        = string
}

variable "secondary_range_services" {
  description = "Subnet secondary range name used for services."
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork name or self link."
  type        = string
}

variable "vertical_pod_autoscaling" {
  description = "Enable the Vertical Pod Autoscaling feature."
  type        = bool
  default     = null
}

variable "workload_identity" {
  description = "Enable the Workload Identity feature."
  type        = bool
  default     = true
}

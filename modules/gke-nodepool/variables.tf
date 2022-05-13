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

variable "autoscaling_config" {
  description = "Optional autoscaling configuration."
  type = object({
    min_node_count = number
    max_node_count = number
  })
  default = null
}

variable "cluster_name" {
  description = "Cluster name."
  type        = string
}

variable "gke_version" {
  description = "Kubernetes nodes version. Ignored if auto_upgrade is set in management_config."
  type        = string
  default     = null
}

variable "initial_node_count" {
  description = "Initial number of nodes for the pool."
  type        = number
  default     = 1
}

variable "kubelet_config" {
  description = "Kubelet configuration."
  type = object({
    cpu_cfs_quota        = string
    cpu_cfs_quota_period = string
    cpu_manager_policy   = string
  })
  default = null
}

variable "linux_node_config_sysctls" {
  description = "Linux node configuration."
  type        = map(string)
  default     = null
}

variable "location" {
  description = "Cluster location."
  type        = string
}

variable "management_config" {
  description = "Optional node management configuration."
  type = object({
    auto_repair  = bool
    auto_upgrade = bool
  })
  default = null
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node."
  type        = number
  default     = null
}

variable "name" {
  description = "Optional nodepool name."
  type        = string
  default     = null
}

variable "node_boot_disk_kms_key" {
  description = "Customer Managed Encryption Key used to encrypt the boot disk attached to each node."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes per instance group, can be updated after creation. Ignored when autoscaling is set."
  type        = number
  default     = null
}

variable "node_disk_size" {
  description = "Node disk size, defaults to 100GB."
  type        = number
  default     = 100
}

variable "node_disk_type" {
  description = "Node disk type, defaults to pd-standard."
  type        = string
  default     = "pd-standard"
}

variable "node_guest_accelerator" {
  description = "Map of type and count of attached accelerator cards."
  type        = map(number)
  default     = {}
}

variable "node_image_type" {
  description = "Nodes image type."
  type        = string
  default     = null
}

variable "node_labels" {
  description = "Kubernetes labels attached to nodes."
  type        = map(string)
  default     = {}
}

variable "node_local_ssd_count" {
  description = "Number of local SSDs attached to nodes."
  type        = number
  default     = 0
}
variable "node_locations" {
  description = "Optional list of zones in which nodes should be located. Uses cluster locations if unset."
  type        = list(string)
  default     = null
}

variable "node_machine_type" {
  description = "Nodes machine type."
  type        = string
  default     = "n1-standard-1"
}

variable "node_metadata" {
  description = "Metadata key/value pairs assigned to nodes. Set disable-legacy-endpoints to true when using this variable."
  type        = map(string)
  default     = null
}

variable "node_min_cpu_platform" {
  description = "Minimum CPU platform for nodes."
  type        = string
  default     = null
}

variable "node_preemptible" {
  description = "Use preemptible VMs for nodes."
  type        = bool
  default     = null
}

variable "node_sandbox_config" {
  description = "GKE Sandbox configuration. Needs image_type set to COS_CONTAINERD and node_version set to 1.12.7-gke.17 when using this variable."
  type        = string
  default     = null
}

variable "node_service_account" {
  description = "Service account email. Unused if service account is auto-created."
  type        = string
  default     = null
}

variable "node_service_account_create" {
  description = "Auto-create service account."
  type        = bool
  default     = false
}

# scopes and scope aliases list
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--scopes
variable "node_service_account_scopes" {
  description = "Scopes applied to service account. Default to: 'cloud-platform' when creating a service account; 'devstorage.read_only', 'logging.write', 'monitoring.write' otherwise."
  type        = list(string)
  default     = []
}

variable "node_shielded_instance_config" {
  description = "Shielded instance options."
  type = object({
    enable_secure_boot          = bool
    enable_integrity_monitoring = bool
  })
  default = null
}

variable "node_spot" {
  description = "Use Spot VMs for nodes."
  type        = bool
  default     = null
}

variable "node_tags" {
  description = "Network tags applied to nodes."
  type        = list(string)
  default     = null
}

variable "node_taints" {
  description = "Kubernetes taints applied to nodes. E.g. type=blue:NoSchedule."
  type        = list(string)
  default     = []
}


variable "project_id" {
  description = "Cluster project id."
  type        = string
}

variable "upgrade_config" {
  description = "Optional node upgrade configuration."
  type = object({
    max_surge       = number
    max_unavailable = number
  })
  default = null
}

variable "workload_metadata_config" {
  description = "Metadata configuration to expose to workloads on the node pool."
  type        = string
  default     = "GKE_METADATA"
}

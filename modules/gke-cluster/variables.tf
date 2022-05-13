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

variable "addons" {
  description = "Addons enabled in the cluster (true means enabled)."
  type = object({
    cloudrun_config            = bool
    dns_cache_config           = bool
    horizontal_pod_autoscaling = bool
    http_load_balancing        = bool
    istio_config = object({
      enabled = bool
      tls     = bool
    })
    network_policy_config                 = bool
    gce_persistent_disk_csi_driver_config = bool
    gcp_filestore_csi_driver_config       = bool
    config_connector_config               = bool
    kalm_config                           = bool
    gke_backup_agent_config               = bool
  })
  default = {
    cloudrun_config            = false
    dns_cache_config           = false
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
    istio_config = {
      enabled = false
      tls     = false
    }
    network_policy_config                 = false
    gce_persistent_disk_csi_driver_config = false
    gcp_filestore_csi_driver_config       = false
    config_connector_config               = false
    kalm_config                           = false
    gke_backup_agent_config               = false
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

variable "dns_config" {
  description = "Configuration for Using Cloud DNS for GKE."
  type = object({
    cluster_dns        = string
    cluster_dns_scope  = string
    cluster_dns_domain = string
  })
  default = null
}

variable "enable_autopilot" {
  description = "Create cluster in autopilot mode. With autopilot there's no need to create node-pools and some features are not supported (e.g. setting default_max_pods_per_node)."
  type        = bool
  default     = false
}

variable "enable_binary_authorization" {
  description = "Enable Google Binary Authorization."
  type        = bool
  default     = null
}

variable "enable_dataplane_v2" {
  description = "Enable Dataplane V2 on the cluster, will disable network_policy addons config."
  type        = bool
  default     = false
}

variable "enable_intranode_visibility" {
  description = "Enable intra-node visibility to make same node pod to pod traffic visible."
  type        = bool
  default     = null
}

variable "enable_l4_ilb_subsetting" {
  description = "Enable L4ILB Subsetting."
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

variable "logging_config" {
  description = "Logging configuration (enabled components)."
  type        = list(string)
  default     = null
}

variable "logging_service" {
  description = "Logging service (disable with an empty string)."
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "maintenance_config" {
  description = "Maintenance window configuration."
  type = object({
    daily_maintenance_window = object({
      start_time = string
    })
    recurring_window = object({
      start_time = string
      end_time   = string
      recurrence = string
    })
    maintenance_exclusion = list(object({
      exclusion_name = string
      start_time     = string
      end_time       = string
    }))
  })
  default = {
    daily_maintenance_window = {
      start_time = "03:00"
    }
    recurring_window      = null
    maintenance_exclusion = []
  }
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

variable "monitoring_config" {
  description = "Monitoring configuration (enabled components)."
  type        = list(string)
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

variable "notification_config" {
  description = "GKE Cluster upgrade notifications via PubSub."
  type        = bool
  default     = false
}

variable "peering_config" {
  description = "Configure peering with the master VPC for private clusters."
  type = object({
    export_routes = bool
    import_routes = bool
    project_id    = string
  })
  default = null
}

variable "pod_security_policy" {
  description = "Enable the PodSecurityPolicy feature."
  type        = bool
  default     = null
}

variable "private_cluster_config" {
  description = "Enable and configure private cluster, private nodes must be true if used."
  type = object({
    enable_private_nodes    = bool
    enable_private_endpoint = bool
    master_ipv4_cidr_block  = string
    master_global_access    = bool
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

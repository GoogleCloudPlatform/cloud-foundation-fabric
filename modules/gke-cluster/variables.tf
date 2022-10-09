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

variable "cluster_autoscaling" {
  description = "Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler."
  type = object({
    auto_provisioning_defaults = optional(object({
      boot_disk_kms_key = optional(string)
      image_type        = optional(string)
      oauth_scopes      = optional(list(string))
      service_account   = optional(string)
    }))
    cpu_limits = optional(object({
      min = number
      max = number
    }))
    memory_limits = optional(object({
      min = number
      max = number
    }))
  })
  default = null
}

variable "database_encryption" {
  description = "Enable and configure GKE application-layer secrets encryption."
  type = object({
    state    = string
    key_name = string
  })
  default = null
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node in this cluster."
  type        = number
  default     = 110
}

variable "description" {
  description = "Cluster description."
  type        = string
  default     = null
}

variable "dns" {
  description = "Configuration for Using Cloud DNS for GKE."
  type = object({
    cluster_dns        = optional(string)
    cluster_dns_scope  = optional(string)
    cluster_dns_domain = optional(string)
  })
  default = null
}

variable "enable_addons" {
  description = "Addons enabled in the cluster (true means enabled)."
  type = object({
    cloudrun_config            = optional(bool)
    dns_cache_config           = optional(bool)
    horizontal_pod_autoscaling = optional(bool)
    http_load_balancing        = optional(bool)
    istio_config = optional(object({
      enabled = bool
      tls     = bool
    }))
    network_policy_config                 = optional(bool)
    gce_persistent_disk_csi_driver_config = optional(bool)
    gcp_filestore_csi_driver_config       = optional(bool)
    config_connector_config               = optional(bool)
    kalm_config                           = optional(bool)
    gke_backup_agent_config               = optional(bool)
  })
  default = {
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
  }
}

variable "enable_features" {
  description = "Enable cluster-level features."
  type = object({
    autopilot                = optional(bool)
    binary_authorization     = optional(bool)
    dataplane_v2             = optional(bool)
    intranode_visibility     = optional(bool)
    l4_ilb_subsetting        = optional(bool)
    pod_security_policy      = optional(bool)
    shielded_nodes           = optional(bool)
    tpu                      = optional(bool)
    vertical_pod_autoscaling = optional(bool)
    workload_identity        = optional(bool)
  })
  default = {
    workload_identity = true
  }
}

variable "gke_groups" {
  description = "RBAC security group for Google Groups for GKE, format is gke-security-groups@yourdomain.com."
  type        = string
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

variable "logging_components" {
  description = "Logging configuration."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "maintenance" {
  description = "Maintenance window configuration."
  type = optional(object({
    daily_window_start_time = optional(string)
    recurring_window = optional(object({
      start_time = string
      end_time   = string
      recurrence = string
    }))
    maintenance_exclusions = optional(list(object({
      exclusion_name = string
      start_time     = string
      end_time       = string
      scope          = optional(string)
    })))
  }))
  default = {
    daily_window_start_time = "03:00"
    recurring_window        = null
    maintenance_exclusion   = []
  }
}

variable "min_master_version" {
  description = "Minimum version of the master, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "monitoring_components" {
  description = "Monitoring components."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "name" {
  description = "Cluster name."
  type        = string
}

variable "node_locations" {
  description = "Zones in which the cluster's nodes are located."
  type        = list(string)
  default     = []
}

variable "notifications" {
  description = "GKE Cluster upgrade notifications via PubSub."
  type        = bool
  default     = false
}

variable "private_cluster" {
  description = "Enable and configure private cluster, private nodes must be true if used."
  type = object({
    enable_private_nodes    = optional(bool)
    enable_private_endpoint = optional(bool)
    master_ipv4_cidr_block  = optional(string)
    master_global_access    = optional(bool)
    peering_config = optional(object({
      export_routes = optional(bool)
      import_routes = optional(bool)
      project_id    = string
    }))
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

variable "resource_usage_export" {
  description = "Configure the ResourceUsageExportConfig feature."
  type = object({
    dataset                              = string
    enable_network_egress_metering       = optional(bool)
    enable_resource_consumption_metering = optional(bool)
  })
  default = null
}

variable "vpc" {
  description = "VPC-level configuration."
  type = object({
    network    = string
    subnetwork = string
    secondary_ranges = optional(object({
      pods     = string
      services = string
    }))
    master_authorized_ranges = optional(map(string))
  })
}

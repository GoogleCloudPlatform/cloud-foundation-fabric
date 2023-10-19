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

variable "backup_configs" {
  description = "Configuration for Backup for GKE."
  type = object({
    enable_backup_agent = optional(bool, false)
    backup_plans = optional(map(object({
      encryption_key                    = optional(string)
      include_secrets                   = optional(bool, true)
      include_volume_data               = optional(bool, true)
      namespaces                        = optional(list(string))
      region                            = string
      schedule                          = string
      retention_policy_days             = optional(string)
      retention_policy_lock             = optional(bool, false)
      retention_policy_delete_lock_days = optional(string)
    })), {})
  })
  default  = {}
  nullable = false
}

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
    mem_limits = optional(object({
      min = number
      max = number
    }))
  })
  default = null
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the cluster. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the cluster will fail."
  type        = bool
  default     = true
  nullable    = false
}

variable "description" {
  description = "Cluster description."
  type        = string
  default     = null
}

variable "enable_addons" {
  description = "Addons enabled in the cluster (true means enabled)."
  type = object({
    cloudrun                       = optional(bool, false)
    config_connector               = optional(bool, false)
    dns_cache                      = optional(bool, false)
    gce_persistent_disk_csi_driver = optional(bool, false)
    gcp_filestore_csi_driver       = optional(bool, false)
    horizontal_pod_autoscaling     = optional(bool, false)
    http_load_balancing            = optional(bool, false)
    istio = optional(object({
      enable_tls = bool
    }))
    kalm           = optional(bool, false)
    network_policy = optional(bool, false)
  })
  default = {
    horizontal_pod_autoscaling = true
    http_load_balancing        = true
  }
  nullable = false
}

variable "enable_features" {
  description = "Enable cluster-level features. Certain features allow configuration."
  type = object({
    binary_authorization = optional(bool, false)
    cost_management      = optional(bool, false)
    dns = optional(object({
      provider = optional(string)
      scope    = optional(string)
      domain   = optional(string)
    }))
    database_encryption = optional(object({
      state    = string
      key_name = string
    }))
    dataplane_v2         = optional(bool, false)
    fqdn_network_policy  = optional(bool, false)
    gateway_api          = optional(bool, false)
    groups_for_rbac      = optional(string)
    intranode_visibility = optional(bool, false)
    l4_ilb_subsetting    = optional(bool, false)
    mesh_certificates    = optional(bool)
    pod_security_policy  = optional(bool, false)
    resource_usage_export = optional(object({
      dataset                              = string
      enable_network_egress_metering       = optional(bool)
      enable_resource_consumption_metering = optional(bool)
    }))
    shielded_nodes = optional(bool, false)
    tpu            = optional(bool, false)
    upgrade_notifications = optional(object({
      topic_id = optional(string)
    }))
    vertical_pod_autoscaling = optional(bool, false)
    workload_identity        = optional(bool, true)
  })
  default = {
    workload_identity = true
  }
  validation {
    condition = (
      var.enable_features.fqdn_network_policy ? var.enable_features.dataplane_v2 : true
    )
    error_message = "FQDN network policy is only supported for clusters with Dataplane v2."
  }
}

variable "issue_client_certificate" {
  description = "Enable issuing client certificate."
  type        = bool
  default     = false
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
  description = "Logging configuration."
  type = object({
    enable_system_logs             = optional(bool, true)
    enable_workloads_logs          = optional(bool, false)
    enable_api_server_logs         = optional(bool, false)
    enable_scheduler_logs          = optional(bool, false)
    enable_controller_manager_logs = optional(bool, false)
  })
  default  = {}
  nullable = false
  # System logs are the minimum required component for enabling log collection.
  # So either everything is off (false), or enable_system_logs must be true.
  validation {
    condition = (
      !anytrue(values(var.logging_config)) || var.logging_config.enable_system_logs
    )
    error_message = "System logs are the minimum required component for enabling log collection."
  }
}

variable "maintenance_config" {
  description = "Maintenance window configuration."
  type = object({
    daily_window_start_time = optional(string)
    recurring_window = optional(object({
      start_time = string
      end_time   = string
      recurrence = string
    }))
    maintenance_exclusions = optional(list(object({
      name       = string
      start_time = string
      end_time   = string
      scope      = optional(string)
    })))
  })
  default = {
    daily_window_start_time = "03:00"
    recurring_window        = null
    maintenance_exclusion   = []
  }
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node in this cluster."
  type        = number
  default     = 110
}

variable "min_master_version" {
  description = "Minimum version of the master, defaults to the version of the most recent official release."
  type        = string
  default     = null
}

variable "monitoring_config" {
  description = "Monitoring configuration. Google Cloud Managed Service for Prometheus is enabled by default."
  type = object({
    enable_system_metrics = optional(bool, true)

    # Control plane metrics
    enable_api_server_metrics         = optional(bool, false)
    enable_controller_manager_metrics = optional(bool, false)
    enable_scheduler_metrics          = optional(bool, false)

    # Kube state metrics
    enable_daemonset_metrics   = optional(bool, false)
    enable_deployment_metrics  = optional(bool, false)
    enable_hpa_metrics         = optional(bool, false)
    enable_pod_metrics         = optional(bool, false)
    enable_statefulset_metrics = optional(bool, false)
    enable_storage_metrics     = optional(bool, false)

    # Google Cloud Managed Service for Prometheus
    enable_managed_prometheus = optional(bool, true)
  })
  default  = {}
  nullable = false
  validation {
    condition = anytrue([
      var.monitoring_config.enable_api_server_metrics,
      var.monitoring_config.enable_controller_manager_metrics,
      var.monitoring_config.enable_scheduler_metrics,
      var.monitoring_config.enable_daemonset_metrics,
      var.monitoring_config.enable_deployment_metrics,
      var.monitoring_config.enable_hpa_metrics,
      var.monitoring_config.enable_pod_metrics,
      var.monitoring_config.enable_statefulset_metrics,
      var.monitoring_config.enable_storage_metrics,
    ]) ? var.monitoring_config.enable_system_metrics : true
    error_message = "System metrics are the minimum required component for enabling metrics collection."
  }
  validation {
    condition = anytrue([
      var.monitoring_config.enable_daemonset_metrics,
      var.monitoring_config.enable_deployment_metrics,
      var.monitoring_config.enable_hpa_metrics,
      var.monitoring_config.enable_pod_metrics,
      var.monitoring_config.enable_statefulset_metrics,
      var.monitoring_config.enable_storage_metrics,
    ]) ? var.monitoring_config.enable_managed_prometheus : true
    error_message = "Kube state metrics collection requires Google Cloud Managed Service for Prometheus to be enabled."
  }
}

variable "name" {
  description = "Cluster name."
  type        = string
}

variable "node_locations" {
  description = "Zones in which the cluster's nodes are located."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "private_cluster_config" {
  description = "Private cluster configuration."
  type = object({
    enable_private_endpoint = optional(bool)
    master_global_access    = optional(bool)
    peering_config = optional(object({
      export_routes = optional(bool)
      import_routes = optional(bool)
      project_id    = optional(string)
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

variable "service_account" {
  description = "Service account used for the default node pool, only useful if the default GCE service account has been disabled."
  type        = string
  default     = null
}

variable "tags" {
  description = "Network tags applied to nodes."
  type        = list(string)
  default     = null
}

variable "vpc_config" {
  description = "VPC-level configuration."
  type = object({
    network                = string
    subnetwork             = string
    master_ipv4_cidr_block = optional(string)
    secondary_range_blocks = optional(object({
      pods     = string
      services = string
    }))
    secondary_range_names = optional(object({
      pods     = optional(string, "pods")
      services = optional(string, "services")
    }))
    master_authorized_ranges = optional(map(string))
    stack_type               = optional(string)
  })
  nullable = false
}

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

locals {
  cas        = var.cluster_autoscaling
  cas_apd    = try(local.cas.auto_provisioning_defaults, null)
  cas_apd_us = try(local.cas_apd.upgrade_settings, null)
}

resource "google_container_cluster" "cluster" {
  provider    = google-beta
  project     = var.project_id
  name        = var.name
  description = var.description
  location    = var.location
  node_locations = (
    length(var.node_locations) == 0 ? null : var.node_locations
  )
  min_master_version                       = var.min_master_version
  network                                  = var.vpc_config.network
  subnetwork                               = var.vpc_config.subnetwork
  resource_labels                          = var.labels
  default_max_pods_per_node                = var.max_pods_per_node
  enable_intranode_visibility              = var.enable_features.intranode_visibility
  enable_l4_ilb_subsetting                 = var.enable_features.l4_ilb_subsetting
  enable_shielded_nodes                    = var.enable_features.shielded_nodes
  enable_fqdn_network_policy               = var.enable_features.fqdn_network_policy
  enable_tpu                               = var.enable_features.tpu
  initial_node_count                       = var.default_nodepool.initial_node_count
  remove_default_node_pool                 = var.default_nodepool.remove_pool
  deletion_protection                      = var.deletion_protection
  enable_cilium_clusterwide_network_policy = var.enable_features.cilium_clusterwide_network_policy
  datapath_provider = (
    var.enable_features.dataplane_v2
    ? "ADVANCED_DATAPATH"
    : "DATAPATH_PROVIDER_UNSPECIFIED"
  )
  # the default node pool is deleted here, use the gke-nodepool module instead.
  # shielded nodes are controlled by the cluster-level enable_features variable
  node_config {
    boot_disk_kms_key = var.node_config.boot_disk_kms_key
    service_account   = var.node_config.service_account
    tags              = var.node_config.tags
    dynamic "shielded_instance_config" {
      for_each = var.enable_features.shielded_nodes ? [""] : []
      content {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }
  # gcfs_config deactivation need the block to be defined so it can't be dynamic
  node_pool_defaults {
    node_config_defaults {
      gcfs_config {
        enabled = var.enable_features.image_streaming
      }
    }
  }
  addons_config {
    dns_cache_config {
      enabled = var.enable_addons.dns_cache
    }
    http_load_balancing {
      disabled = !var.enable_addons.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.enable_addons.horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = !var.enable_addons.network_policy
    }
    cloudrun_config {
      disabled = !var.enable_addons.cloudrun
    }
    istio_config {
      disabled = var.enable_addons.istio == null
      auth = (
        try(var.enable_addons.istio.enable_tls, false) ? "AUTH_MUTUAL_TLS" : "AUTH_NONE"
      )
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_addons.gce_persistent_disk_csi_driver
    }
    gcp_filestore_csi_driver_config {
      enabled = var.enable_addons.gcp_filestore_csi_driver
    }
    gcs_fuse_csi_driver_config {
      enabled = var.enable_addons.gcs_fuse_csi_driver
    }
    kalm_config {
      enabled = var.enable_addons.kalm
    }
    config_connector_config {
      enabled = var.enable_addons.config_connector
    }
    gke_backup_agent_config {
      enabled = var.backup_configs.enable_backup_agent
    }
  }
  dynamic "authenticator_groups_config" {
    for_each = var.enable_features.groups_for_rbac != null ? [""] : []
    content {
      security_group = var.enable_features.groups_for_rbac
    }
  }
  dynamic "binary_authorization" {
    for_each = var.enable_features.binary_authorization ? [""] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }
  dynamic "cost_management_config" {
    for_each = var.enable_features.cost_management == true ? [""] : []
    content {
      enabled = true
    }
  }
  dynamic "cluster_autoscaling" {
    for_each = local.cas == null ? [] : [""]
    content {
      enabled             = true
      autoscaling_profile = var.cluster_autoscaling.autoscaling_profile
      dynamic "auto_provisioning_defaults" {
        for_each = local.cas_apd != null ? [""] : []
        content {
          boot_disk_kms_key = local.cas_apd.boot_disk_kms_key
          disk_size         = local.cas_apd.disk_size
          disk_type         = local.cas_apd.disk_type
          image_type        = local.cas_apd.image_type
          oauth_scopes      = local.cas_apd.oauth_scopes
          service_account   = local.cas_apd.service_account
          dynamic "management" {
            for_each = local.cas_apd.management != null ? [""] : []
            content {
              auto_repair  = local.cas_apd.management.auto_repair
              auto_upgrade = local.cas_apd.management.auto_upgrade
            }
          }
          dynamic "shielded_instance_config" {
            for_each = local.cas_apd.shielded_instance_config != null ? [""] : []
            content {
              enable_integrity_monitoring = (
                local.cas_apd.shielded_instance_config.integrity_monitoring
              )
              enable_secure_boot = (
                local.cas_apd.shielded_instance_config.secure_boot
              )
            }
          }
          dynamic "upgrade_settings" {
            for_each = local.cas_apd_us != null ? [""] : []
            content {
              strategy = (
                local.cas_apd_us.blue_green != null ? "BLUE_GREEN" : "SURGE"
              )
              max_surge       = try(local.cas_apd_us.surge.max, null)
              max_unavailable = try(local.cas_apd_us.surge.unavailable, null)
              dynamic "blue_green_settings" {
                for_each = local.cas_apd_us.blue_green != null ? [""] : []
                content {
                  node_pool_soak_duration = (
                    local.cas_apd_us.blue_green.node_pool_soak_duration
                  )
                  dynamic "standard_rollout_policy" {
                    for_each = (
                      local.cas_apd_us.blue_green.standard_rollout_policy != null
                      ? [""]
                      : []
                    )
                    content {
                      batch_node_count = (
                        local.cas_apd_us.blue_green.standard_rollout_policy.batch_node_count
                      )
                      batch_percentage = (
                        local.cas_apd_us.blue_green.standard_rollout_policy.batch_percentage
                      )
                      batch_soak_duration = (
                        local.cas_apd_us.blue_green.standard_rollout_policy.batch_soak_duration
                      )
                    }
                  }
                }
              }
            }
          }
        }
      }
      dynamic "resource_limits" {
        for_each = local.cas.cpu_limits != null ? [""] : []
        content {
          resource_type = "cpu"
          minimum       = local.cas.cpu_limits.min
          maximum       = local.cas.cpu_limits.max
        }
      }
      dynamic "resource_limits" {
        for_each = local.cas.mem_limits != null ? [""] : []
        content {
          resource_type = "memory"
          minimum       = local.cas.mem_limits.min
          maximum       = local.cas.mem_limits.max
        }
      }
      dynamic "resource_limits" {
        for_each = (
          try(local.cas.gpu_resources, null) == null
          ? []
          : local.cas.gpu_resources
        )
        iterator = gpu_resources
        content {
          resource_type = gpu_resources.value.resource_type
          minimum       = gpu_resources.value.min
          maximum       = gpu_resources.value.max
        }
      }
    }
  }
  dynamic "database_encryption" {
    for_each = var.enable_features.database_encryption != null ? [""] : []
    content {
      state    = var.enable_features.database_encryption.state
      key_name = var.enable_features.database_encryption.key_name
    }
  }
  dynamic "dns_config" {
    for_each = var.enable_features.dns != null ? [""] : []
    content {
      cluster_dns        = var.enable_features.dns.provider
      cluster_dns_scope  = var.enable_features.dns.scope
      cluster_dns_domain = var.enable_features.dns.domain
    }
  }
  dynamic "enable_k8s_beta_apis" {
    for_each = var.enable_features.beta_apis != null ? [""] : []
    content {
      enabled_apis = var.enable_features.beta_apis
    }
  }
  dynamic "gateway_api_config" {
    for_each = var.enable_features.gateway_api ? [""] : []
    content {
      channel = "CHANNEL_STANDARD"
    }
  }
  dynamic "ip_allocation_policy" {
    for_each = var.vpc_config.secondary_range_blocks != null ? [""] : []
    content {
      cluster_ipv4_cidr_block = (
        var.vpc_config.secondary_range_blocks.pods
      )
      services_ipv4_cidr_block = (
        var.vpc_config.secondary_range_blocks.services
      )
      stack_type = var.vpc_config.stack_type
    }
  }
  dynamic "ip_allocation_policy" {
    for_each = var.vpc_config.secondary_range_names != null ? [""] : []
    content {
      cluster_secondary_range_name = (
        var.vpc_config.secondary_range_names.pods
      )
      services_secondary_range_name = (
        var.vpc_config.secondary_range_names.services
      )
      stack_type = var.vpc_config.stack_type
    }
  }
  # Send GKE cluster logs from chosen sources to Cloud Logging.
  # System logs must be enabled if any other source is enabled.
  # This is validated by input variable validation rules.
  dynamic "logging_config" {
    for_each = var.logging_config.enable_system_logs ? [""] : []
    content {
      enable_components = toset(compact([
        var.logging_config.enable_api_server_logs ? "APISERVER" : null,
        var.logging_config.enable_controller_manager_logs ? "CONTROLLER_MANAGER" : null,
        var.logging_config.enable_scheduler_logs ? "SCHEDULER" : null,
        "SYSTEM_COMPONENTS",
        var.logging_config.enable_workloads_logs ? "WORKLOADS" : null,
      ]))
    }
  }
  # Don't send any GKE cluster logs to Cloud Logging. Input variable validation
  # makes sure every other log source is false when enable_system_logs is false.
  dynamic "logging_config" {
    for_each = var.logging_config.enable_system_logs == false ? [""] : []
    content {
      enable_components = []
    }
  }
  maintenance_policy {
    dynamic "daily_maintenance_window" {
      for_each = (
        try(var.maintenance_config.daily_window_start_time, null) != null
        ? [""]
        : []
      )
      content {
        start_time = var.maintenance_config.daily_window_start_time
      }
    }
    dynamic "recurring_window" {
      for_each = (
        try(var.maintenance_config.recurring_window, null) != null
        ? [""]
        : []
      )
      content {
        start_time = var.maintenance_config.recurring_window.start_time
        end_time   = var.maintenance_config.recurring_window.end_time
        recurrence = var.maintenance_config.recurring_window.recurrence
      }
    }
    dynamic "maintenance_exclusion" {
      for_each = (
        try(var.maintenance_config.maintenance_exclusions, null) == null
        ? []
        : var.maintenance_config.maintenance_exclusions
      )
      iterator = exclusion
      content {
        exclusion_name = exclusion.value.name
        start_time     = exclusion.value.start_time
        end_time       = exclusion.value.end_time
        dynamic "exclusion_options" {
          for_each = exclusion.value.scope != null ? [""] : []
          content {
            scope = exclusion.value.scope
          }
        }
      }
    }
  }
  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }
  dynamic "master_authorized_networks_config" {
    for_each = var.vpc_config.master_authorized_ranges != null ? [""] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.vpc_config.master_authorized_ranges
        iterator = range
        content {
          cidr_block   = range.value
          display_name = range.key
        }
      }
    }
  }
  dynamic "mesh_certificates" {
    for_each = var.enable_features.mesh_certificates != null ? [""] : []
    content {
      enable_certificates = var.enable_features.mesh_certificates
    }
  }
  monitoring_config {
    enable_components = toset(compact([
      # System metrics is the minimum requirement if any other metrics are enabled.
      # This is checked by input var validation.
      var.monitoring_config.enable_system_metrics ? "SYSTEM_COMPONENTS" : null,
      # Control plane metrics
      var.monitoring_config.enable_api_server_metrics ? "APISERVER" : null,
      var.monitoring_config.enable_controller_manager_metrics ? "CONTROLLER_MANAGER" : null,
      var.monitoring_config.enable_scheduler_metrics ? "SCHEDULER" : null,
      # Kube state metrics
      var.monitoring_config.enable_daemonset_metrics ? "DAEMONSET" : null,
      var.monitoring_config.enable_deployment_metrics ? "DEPLOYMENT" : null,
      var.monitoring_config.enable_hpa_metrics ? "HPA" : null,
      var.monitoring_config.enable_pod_metrics ? "POD" : null,
      var.monitoring_config.enable_statefulset_metrics ? "STATEFULSET" : null,
      var.monitoring_config.enable_storage_metrics ? "STORAGE" : null,
    ]))
    managed_prometheus {
      enabled = var.monitoring_config.enable_managed_prometheus
    }
    dynamic "advanced_datapath_observability_config" {
      for_each = (
        var.monitoring_config.advanced_datapath_observability == null
        ? []
        : [""]
      )
      content {
        enable_metrics = (
          var.monitoring_config.advanced_datapath_observability.enable_metrics
        )
        enable_relay = (
          var.monitoring_config.advanced_datapath_observability.enable_relay
        )
        relay_mode = (
          var.monitoring_config.advanced_datapath_observability.relay_mode
        )
      }
    }
  }
  # Dataplane V2 has built-in network policies
  dynamic "network_policy" {
    for_each = (
      var.enable_addons.network_policy && !var.enable_features.dataplane_v2
      ? [""]
      : []
    )
    content {
      enabled  = true
      provider = "CALICO"
    }
  }
  dynamic "notification_config" {
    for_each = var.enable_features.upgrade_notifications != null ? [""] : []
    content {
      pubsub {
        enabled = true
        topic = (
          try(var.enable_features.upgrade_notifications.topic_id, null) != null
          ? var.enable_features.upgrade_notifications.topic_id
          : google_pubsub_topic.notifications[0].id
        )
      }
    }
  }
  dynamic "private_cluster_config" {
    for_each = (
      var.private_cluster_config != null ? [""] : []
    )
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.private_cluster_config.enable_private_endpoint
      master_ipv4_cidr_block  = try(var.vpc_config.master_ipv4_cidr_block, null)
      master_global_access_config {
        enabled = var.private_cluster_config.master_global_access
      }
    }
  }
  dynamic "pod_security_policy_config" {
    for_each = var.enable_features.pod_security_policy ? [""] : []
    content {
      enabled = var.enable_features.pod_security_policy
    }
  }
  dynamic "release_channel" {
    for_each = var.release_channel != null ? [""] : []
    content {
      channel = var.release_channel
    }
  }
  dynamic "resource_usage_export_config" {
    for_each = (
      try(var.enable_features.resource_usage_export.dataset, null) != null
      ? [""]
      : []
    )
    content {
      enable_network_egress_metering = (
        var.enable_features.resource_usage_export.enable_network_egress_metering
      )
      enable_resource_consumption_metering = (
        var.enable_features.resource_usage_export.enable_resource_consumption_metering
      )
      bigquery_destination {
        dataset_id = var.enable_features.resource_usage_export.dataset
      }
    }
  }
  dynamic "service_external_ips_config" {
    for_each = !var.enable_features.service_external_ips ? [""] : []
    content {
      enabled = var.enable_features.service_external_ips
    }
  }
  dynamic "vertical_pod_autoscaling" {
    for_each = var.enable_features.vertical_pod_autoscaling ? [""] : []
    content {
      enabled = var.enable_features.vertical_pod_autoscaling
    }
  }
  dynamic "workload_identity_config" {
    for_each = var.enable_features.workload_identity ? [""] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }
  lifecycle {
    ignore_changes = [node_config]
  }
}

resource "google_gke_backup_backup_plan" "backup_plan" {
  for_each = (
    var.backup_configs.enable_backup_agent
    ? var.backup_configs.backup_plans
    : {}
  )
  name     = each.key
  cluster  = google_container_cluster.cluster.id
  location = each.value.region
  project  = var.project_id
  retention_policy {
    backup_delete_lock_days = try(each.value.retention_policy_delete_lock_days)
    backup_retain_days      = try(each.value.retention_policy_days)
    locked                  = try(each.value.retention_policy_lock)
  }
  backup_schedule {
    cron_schedule = each.value.schedule
  }
  backup_config {
    include_volume_data = each.value.include_volume_data
    include_secrets     = each.value.include_secrets
    dynamic "encryption_key" {
      for_each = each.value.encryption_key != null ? [""] : []
      content {
        gcp_kms_encryption_key = each.value.encryption_key
      }
    }
    all_namespaces = (
      lookup(each.value, "namespaces", null) != null
      ||
      lookup(each.value, "applications", null) != null ? null : true
    )
    dynamic "selected_namespaces" {
      for_each = each.value.namespaces != null ? [""] : []
      content {
        namespaces = each.value.namespaces
      }
    }
    dynamic "selected_applications" {
      for_each = each.value.applications != null ? [""] : []
      content {
        dynamic "namespaced_names" {
          for_each = flatten([for k, vs in each.value.applications : [
            for v in vs : { namespace = k, name = v }
          ]])
          content {
            namespace = namespaced_names.value.namespace
            name      = namespaced_names.value.name
          }
        }
      }

    }
  }
}


resource "google_compute_network_peering_routes_config" "gke_master" {
  count = (
    try(var.private_cluster_config.peering_config, null) != null ? 1 : 0
  )
  project = coalesce(var.private_cluster_config.peering_config.project_id, var.project_id)
  peering = try(
    google_container_cluster.cluster.private_cluster_config[0].peering_name,
    null
  )
  network              = element(reverse(split("/", var.vpc_config.network)), 0)
  import_custom_routes = var.private_cluster_config.peering_config.import_routes
  export_custom_routes = var.private_cluster_config.peering_config.export_routes
}

resource "google_pubsub_topic" "notifications" {
  count = (
    try(var.enable_features.upgrade_notifications, null) != null &&
    try(var.enable_features.upgrade_notifications.topic_id, null) == null ? 1 : 0
  )
  project = var.project_id
  name    = "gke-pubsub-notifications"
  labels = {
    content = "gke-notifications"
  }
}

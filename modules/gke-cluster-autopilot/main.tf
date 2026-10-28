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

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p      = "$"
  location   = lookup(local.ctx.locations, var.location, var.location)
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region     = join("-", slice(split("-", local.location), 0, 2))
}

resource "google_container_cluster" "cluster" {
  provider    = google-beta
  project     = local.project_id
  name        = var.name
  description = var.description
  location    = local.location
  node_locations = (
    length(var.node_locations) == 0
    ? null
    : [for v in var.node_locations : lookup(local.ctx.locations, v, v)]
  )
  min_master_version                       = var.min_master_version
  network                                  = lookup(local.ctx.networks, var.vpc_config.network, var.vpc_config.network)
  subnetwork                               = lookup(local.ctx.subnets, var.vpc_config.subnetwork, var.vpc_config.subnetwork)
  disable_l4_lb_firewall_reconciliation    = var.vpc_config.disable_l4_lb_firewall_reconciliation
  resource_labels                          = var.labels
  enable_multi_networking                  = var.enable_features.multi_networking
  enable_l4_ilb_subsetting                 = var.enable_features.l4_ilb_subsetting
  enable_tpu                               = var.enable_features.tpu
  initial_node_count                       = 1
  enable_autopilot                         = true
  allow_net_admin                          = var.enable_features.allow_net_admin
  deletion_protection                      = var.deletion_protection
  enable_cilium_clusterwide_network_policy = var.enable_features.cilium_clusterwide_network_policy
  enable_fqdn_network_policy               = var.enable_features.fqdn_network_policy

  addons_config {
    dynamic "agent_sandbox_config" {
      for_each = var.enable_addons.agent_sandbox != null ? [""] : []
      content {
        enabled = var.enable_addons.agent_sandbox
      }
    }
    # HTTP Load Balancing is required to be enabled in Autopilot clusters
    http_load_balancing {
      disabled = false
    }
    # Horizontal Pod Autoscaling is required to be enabled in Autopilot clusters
    horizontal_pod_autoscaling {
      disabled = false
    }
    cloudrun_config {
      disabled = !var.enable_addons.cloudrun
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
  dynamic "anonymous_authentication_config" {
    for_each = var.enable_features.anonymous_authentication != null ? [""] : []
    content {
      mode = var.enable_features.anonymous_authentication
    }
  }
  dynamic "authenticator_groups_config" {
    for_each = var.enable_features.groups_for_rbac != null ? [""] : []
    content {
      security_group = lookup(
        local.ctx.email_addresses,
        var.enable_features.groups_for_rbac,
        var.enable_features.groups_for_rbac
      )
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
  cluster_autoscaling {
    auto_provisioning_defaults {
      boot_disk_kms_key = (
        var.node_config.boot_disk_kms_key == null
        ? null
        : lookup(local.ctx.kms_keys, var.node_config.boot_disk_kms_key, var.node_config.boot_disk_kms_key)
      )
      service_account = (
        var.node_config.service_account == null
        ? null
        : lookup(local.ctx.iam_principals, var.node_config.service_account, var.node_config.service_account)
      )
    }
  }
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic    = var.access_config.dns_access.allow_external_traffic == true
      enable_k8s_tokens_via_dns = var.access_config.dns_access.enable_k8s_tokens
      enable_k8s_certs_via_dns  = var.access_config.dns_access.enable_k8s_certs
    }
    ip_endpoints_config {
      enabled = var.access_config.ip_access != null
    }
  }
  dynamic "database_encryption" {
    for_each = var.enable_features.database_encryption != null ? [""] : []
    content {
      state = var.enable_features.database_encryption.state
      key_name = lookup(
        local.ctx.kms_keys,
        var.enable_features.database_encryption.key_name,
        var.enable_features.database_encryption.key_name
      )
    }
  }
  dynamic "default_snat_status" {
    for_each = var.vpc_config.disable_default_snat == null ? [] : [""]
    content {
      disabled = var.vpc_config.disable_default_snat
    }
  }
  dynamic "dns_config" {
    for_each = var.enable_features.dns != null ? [""] : []
    content {
      additive_vpc_scope_dns_domain = var.enable_features.dns.additive_vpc_scope_dns_domain
      cluster_dns                   = var.enable_features.dns.provider
      cluster_dns_scope             = var.enable_features.dns.scope
      cluster_dns_domain            = var.enable_features.dns.domain
    }
  }
  dynamic "enable_k8s_beta_apis" {
    for_each = var.enable_features.beta_apis != null ? [""] : []
    content {
      enabled_apis = var.enable_features.beta_apis
    }
  }
  dynamic "fleet" {
    for_each = var.fleet_project != null ? [""] : []
    content {
      project = lookup(local.ctx.project_ids, var.fleet_project, var.fleet_project)
    }
  }
  dynamic "gateway_api_config" {
    for_each = var.enable_features.gateway_api ? [""] : []
    content {
      channel = "CHANNEL_STANDARD"
    }
  }
  dynamic "identity_service_config" {
    for_each = var.enable_features.identity_service ? [""] : []
    content {
      enabled = true
    }
  }
  dynamic "ip_allocation_policy" {
    for_each = var.vpc_config.secondary_range_blocks != null ? [""] : []
    content {
      cluster_ipv4_cidr_block = lookup(
        local.ctx.cidr_ranges,
        var.vpc_config.secondary_range_blocks.pods,
        var.vpc_config.secondary_range_blocks.pods
      )
      services_ipv4_cidr_block = lookup(
        local.ctx.cidr_ranges,
        var.vpc_config.secondary_range_blocks.services,
        var.vpc_config.secondary_range_blocks.services
      )
      stack_type = var.vpc_config.stack_type
      dynamic "additional_pod_ranges_config" {
        for_each = var.vpc_config.additional_ranges != null ? [""] : []
        content {
          pod_range_names = var.vpc_config.additional_ranges
        }
      }
    }
  }
  dynamic "ip_allocation_policy" {
    for_each = var.vpc_config.secondary_range_names != null ? [""] : []
    content {
      cluster_secondary_range_name  = var.vpc_config.secondary_range_names.pods
      services_secondary_range_name = var.vpc_config.secondary_range_names.services
      stack_type                    = var.vpc_config.stack_type
      dynamic "additional_pod_ranges_config" {
        for_each = var.vpc_config.additional_ranges != null ? [""] : []
        content {
          pod_range_names = var.vpc_config.additional_ranges
        }
      }
    }
  }
  logging_config {
    enable_components = toset(compact([
      var.logging_config.enable_api_server_logs ? "APISERVER" : null,
      var.logging_config.enable_controller_manager_logs ? "CONTROLLER_MANAGER" : null,
      var.logging_config.enable_scheduler_logs ? "SCHEDULER" : null,
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
    ]))
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
    for_each = (
      try(var.access_config.ip_access.private_endpoint_authorized_ranges_enforcement, null) != null ||
      try(var.access_config.ip_access.authorized_ranges, null) != null ||
      try(var.access_config.ip_access.gcp_public_cidrs_access_enabled, null) != null
    ) ? [""] : []
    content {
      gcp_public_cidrs_access_enabled = try(
        var.access_config.ip_access.gcp_public_cidrs_access_enabled,
        null
      )
      private_endpoint_enforcement_enabled = try(
        var.access_config.ip_access.private_endpoint_authorized_ranges_enforcement,
        null
      )
      dynamic "cidr_blocks" {
        for_each = coalesce(var.access_config.ip_access.authorized_ranges, {})
        iterator = range
        content {
          cidr_block   = lookup(local.ctx.cidr_ranges, range.value, range.value)
          display_name = range.key
        }
      }
    }
  }
  dynamic "managed_opentelemetry_config" {
    for_each = var.enable_features.managed_opentelemetry != null ? [""] : []
    content {
      scope = (
        var.enable_features.managed_opentelemetry
        ? "COLLECTION_AND_INSTRUMENTATION_COMPONENTS"
        : "NONE"
      )
    }
  }
  dynamic "mesh_certificates" {
    for_each = var.enable_features.mesh_certificates != null ? [""] : []
    content {
      enable_certificates = var.enable_features.mesh_certificates
    }
  }
  monitoring_config {
    enable_components = compact([
      # System metrics collection cannot be disabled for Autopilot clusters.
      "SYSTEM_COMPONENTS",
      # Control plane metrics:
      var.monitoring_config.enable_api_server_metrics ? "APISERVER" : null,
      var.monitoring_config.enable_scheduler_metrics ? "SCHEDULER" : null,
      var.monitoring_config.enable_controller_manager_metrics ? "CONTROLLER_MANAGER" : null,
      # Kube state metrics:
      var.monitoring_config.enable_storage_metrics ? "STORAGE" : null,
      var.monitoring_config.enable_hpa_metrics ? "HPA" : null,
      var.monitoring_config.enable_pod_metrics ? "POD" : null,
      var.monitoring_config.enable_daemonset_metrics ? "DAEMONSET" : null,
      var.monitoring_config.enable_deployment_metrics ? "DEPLOYMENT" : null,
      var.monitoring_config.enable_statefulset_metrics ? "STATEFULSET" : null,
      var.monitoring_config.enable_cadvisor_metrics ? "CADVISOR" : null,
    ])
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
      }
    }
  }
  dynamic "notification_config" {
    for_each = var.enable_features.upgrade_notifications != null ? [""] : []
    content {
      pubsub {
        enabled = var.enable_features.upgrade_notifications.enabled
        dynamic "filter" {
          for_each = var.enable_features.upgrade_notifications.event_types != null ? [""] : []
          content {
            event_type = var.enable_features.upgrade_notifications.event_types
          }
        }
        topic = (
          try(var.enable_features.upgrade_notifications.topic_id, null) != null
          ? lookup(
            local.ctx.pubsub_topics,
            var.enable_features.upgrade_notifications.topic_id,
            var.enable_features.upgrade_notifications.topic_id
          )
          : google_pubsub_topic.notifications[0].id
        )
      }
    }
  }
  node_pool_auto_config {
    node_kubelet_config {
      insecure_kubelet_readonly_port_enabled = try(upper(var.node_config.kubelet_readonly_port_enabled), null)
    }
    dynamic "network_tags" {
      for_each = var.node_config.tags != null ? [""] : []
      content {
        tags = toset(var.node_config.tags)
      }
    }
    resource_manager_tags = {
      for k, v in var.node_config.resource_manager_tags :
      k => lookup(local.ctx.tag_values, v, v)
    }
  }
  dynamic "private_cluster_config" {
    for_each = var.access_config.private_nodes == true ? [""] : []
    content {
      enable_private_nodes = true
      enable_private_endpoint = try(
        var.access_config.ip_access.disable_public_endpoint, null
      )
      master_ipv4_cidr_block = (
        var.access_config.master_ipv4_cidr_block == null
        ? null
        : lookup(local.ctx.cidr_ranges, var.access_config.master_ipv4_cidr_block, var.access_config.master_ipv4_cidr_block)
      )
      private_endpoint_subnetwork = (
        try(var.access_config.ip_access.private_endpoint_config.endpoint_subnetwork, null) == null
        ? null
        : lookup(
          local.ctx.subnets,
          var.access_config.ip_access.private_endpoint_config.endpoint_subnetwork,
          var.access_config.ip_access.private_endpoint_config.endpoint_subnetwork
        )
      )
      dynamic "master_global_access_config" {
        for_each = try(var.access_config.ip_access.private_endpoint_config.global_access, false) == true ? [""] : []
        content {
          enabled = (
            var.access_config.ip_access.private_endpoint_config.global_access
          )
        }
      }
    }
  }
  dynamic "pod_security_policy_config" {
    for_each = var.enable_features.pod_security_policy ? [""] : []
    content {
      enabled = var.enable_features.pod_security_policy
    }
  }
  dynamic "rbac_binding_config" {
    for_each = var.enable_features.rbac_binding_config != null ? [""] : []
    content {
      enable_insecure_binding_system_unauthenticated = var.enable_features.rbac_binding_config.enable_insecure_binding_system_unauthenticated
      enable_insecure_binding_system_authenticated   = var.enable_features.rbac_binding_config.enable_insecure_binding_system_authenticated
    }
  }
  dynamic "secret_manager_config" {
    for_each = var.enable_features.secret_manager_config != null ? [""] : []
    content {
      enabled = var.enable_features.secret_manager_config
    }
  }
  dynamic "secret_sync_config" {
    for_each = var.enable_features.secret_sync_config != null ? [""] : []
    content {
      enabled = var.enable_features.secret_sync_config.enabled
      dynamic "rotation_config" {
        for_each = try(var.enable_features.secret_sync_config.rotation_config, null) != null ? [""] : []
        content {
          enabled           = var.enable_features.secret_sync_config.rotation_config.enabled
          rotation_interval = var.enable_features.secret_sync_config.rotation_config.rotation_interval
        }
      }
    }
  }
  dynamic "security_posture_config" {
    for_each = var.enable_features.security_posture_config != null ? [""] : []
    content {
      mode               = var.enable_features.security_posture_config.mode
      vulnerability_mode = var.enable_features.security_posture_config.vulnerability_mode
    }
  }
  release_channel {
    channel = var.release_channel
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
        dataset_id = lookup(
          local.ctx.bigquery_datasets,
          var.enable_features.resource_usage_export.dataset,
          var.enable_features.resource_usage_export.dataset
        )
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
}

resource "google_gke_backup_backup_channel" "backup_channel" {
  for_each = var.backup_configs.backup_channels
  name     = each.key
  project  = local.project_id
  location = coalesce(
    try(local.ctx.locations[each.value.region], each.value.region),
    local.region
  )
  destination_project = (
    startswith(
      lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project),
      "projects/"
    )
    ? lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project)
    : "projects/${lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project)}"
  )
  deletion_policy = each.value.deletion_policy
  description     = each.value.description
  labels          = each.value.labels
}

resource "google_gke_backup_backup_plan" "backup_plan" {
  for_each = (
    var.backup_configs.enable_backup_agent
    ? var.backup_configs.backup_plans
    : {}
  )
  name    = each.key
  cluster = google_container_cluster.cluster.id
  location = coalesce(
    try(local.ctx.locations[each.value.region], each.value.region),
    local.region
  )
  project         = local.project_id
  deletion_policy = each.value.deletion_policy
  description     = each.value.description
  labels          = each.value.labels
  retention_policy {
    backup_delete_lock_days = try(each.value.retention_policy_delete_lock_days)
    backup_retain_days      = try(each.value.retention_policy_days)
    locked                  = try(each.value.retention_policy_lock)
  }
  dynamic "backup_schedule" {
    for_each = each.value.schedule != null ? [""] : []
    content {
      cron_schedule = each.value.schedule
    }
  }

  backup_config {
    include_volume_data = each.value.include_volume_data
    include_secrets     = each.value.include_secrets
    permissive_mode     = each.value.permissive_mode
    dynamic "encryption_key" {
      for_each = each.value.encryption_key != null ? [""] : []
      content {
        gcp_kms_encryption_key = lookup(
          local.ctx.kms_keys, each.value.encryption_key, each.value.encryption_key
        )
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

resource "google_gke_backup_restore_channel" "restore_channel" {
  for_each = var.backup_configs.restore_channels
  name     = each.key
  project  = local.project_id
  location = coalesce(
    try(local.ctx.locations[each.value.region], each.value.region),
    local.region
  )
  destination_project = (
    startswith(
      lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project),
      "projects/"
    )
    ? lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project)
    : "projects/${lookup(local.ctx.project_ids, each.value.destination_project, each.value.destination_project)}"
  )
  deletion_policy = each.value.deletion_policy
  description     = each.value.description
  labels          = each.value.labels
}

resource "google_gke_backup_restore_plan" "restore_plan" {
  for_each = (
    var.backup_configs.enable_backup_agent
    ? var.backup_configs.restore_plans
    : {}
  )
  name    = each.key
  cluster = google_container_cluster.cluster.id
  location = coalesce(
    try(local.ctx.locations[each.value.region], each.value.region),
    local.region
  )
  project = local.project_id
  backup_plan = try(
    google_gke_backup_backup_plan.backup_plan[each.value.backup_plan].id,
    each.value.backup_plan
  )
  deletion_policy = each.value.deletion_policy
  description     = each.value.description
  labels          = each.value.labels
  restore_config {
    all_namespaces = (
      each.value.namespaced_restore_scope.all_namespaces == true || (
        each.value.namespaced_restore_scope.no_namespaces != true &&
        each.value.namespaced_restore_scope.selected_namespaces == null &&
        each.value.namespaced_restore_scope.excluded_namespaces == null &&
        each.value.namespaced_restore_scope.applications == null
      ) ? true : null
    )
    no_namespaces                    = each.value.namespaced_restore_scope.no_namespaces
    namespaced_resource_restore_mode = each.value.namespaced_restore_scope.restore_mode
    cluster_resource_conflict_policy = try(
      each.value.cluster_resource_restore_scope.conflict_policy, null
    )
    volume_data_restore_policy = try(each.value.volume_data_restore.policy, null)
    dynamic "cluster_resource_restore_scope" {
      for_each = each.value.cluster_resource_restore_scope != null ? [""] : []
      content {
        all_group_kinds = each.value.cluster_resource_restore_scope.all_group_kinds
        no_group_kinds  = each.value.cluster_resource_restore_scope.no_group_kinds
        dynamic "excluded_group_kinds" {
          for_each = coalesce(
            each.value.cluster_resource_restore_scope.excluded_group_kinds, []
          )
          content {
            resource_group = excluded_group_kinds.value.resource_group
            resource_kind  = excluded_group_kinds.value.resource_kind
          }
        }
        dynamic "selected_group_kinds" {
          for_each = coalesce(
            each.value.cluster_resource_restore_scope.selected_group_kinds, []
          )
          content {
            resource_group = selected_group_kinds.value.resource_group
            resource_kind  = selected_group_kinds.value.resource_kind
          }
        }
      }
    }
    dynamic "excluded_namespaces" {
      for_each = each.value.namespaced_restore_scope.excluded_namespaces != null ? [""] : []
      content {
        namespaces = each.value.namespaced_restore_scope.excluded_namespaces
      }
    }
    dynamic "selected_namespaces" {
      for_each = each.value.namespaced_restore_scope.selected_namespaces != null ? [""] : []
      content {
        namespaces = each.value.namespaced_restore_scope.selected_namespaces
      }
    }
    dynamic "selected_applications" {
      for_each = each.value.namespaced_restore_scope.applications != null ? [""] : []
      content {
        dynamic "namespaced_names" {
          for_each = flatten([
            for k, vs in each.value.namespaced_restore_scope.applications : [
              for v in vs : { namespace = k, name = v }
            ]
          ])
          content {
            namespace = namespaced_names.value.namespace
            name      = namespaced_names.value.name
          }
        }
      }
    }
    dynamic "restore_order" {
      for_each = each.value.restore_order != null ? [""] : []
      content {
        dynamic "group_kind_dependencies" {
          for_each = each.value.restore_order
          content {
            requiring {
              resource_group = group_kind_dependencies.value.requiring.resource_group
              resource_kind  = group_kind_dependencies.value.requiring.resource_kind
            }
            satisfying {
              resource_group = group_kind_dependencies.value.satisfying.resource_group
              resource_kind  = group_kind_dependencies.value.satisfying.resource_kind
            }
          }
        }
      }
    }
    dynamic "transformation_rules" {
      for_each = coalesce(each.value.transformation_rules, [])
      content {
        description = transformation_rules.value.description
        dynamic "field_actions" {
          for_each = transformation_rules.value.field_actions
          content {
            from_path = field_actions.value.from_path
            op        = field_actions.value.op
            path      = field_actions.value.path
            value     = field_actions.value.value
          }
        }
        dynamic "resource_filter" {
          for_each = transformation_rules.value.resource_filter != null ? [""] : []
          content {
            json_path  = transformation_rules.value.resource_filter.json_path
            namespaces = transformation_rules.value.resource_filter.namespaces
            dynamic "group_kinds" {
              for_each = coalesce(
                transformation_rules.value.resource_filter.group_kinds, []
              )
              content {
                resource_group = group_kinds.value.resource_group
                resource_kind  = group_kinds.value.resource_kind
              }
            }
          }
        }
      }
    }
    dynamic "volume_data_restore_policy_bindings" {
      for_each = try(each.value.volume_data_restore.bindings, {})
      content {
        volume_type = volume_data_restore_policy_bindings.key
        policy      = volume_data_restore_policy_bindings.value
      }
    }
  }
}

resource "google_pubsub_topic" "notifications" {
  count = (
    try(var.enable_features.upgrade_notifications, null) != null &&
    try(var.enable_features.upgrade_notifications.topic_id, null) == null ? 1 : 0
  )
  project = local.project_id
  name    = "gke-pubsub-notifications"
  labels = {
    content = "gke-notifications"
  }
  kms_key_name = (
    try(var.enable_features.upgrade_notifications.kms_key_name, null) == null
    ? null
    : lookup(
      local.ctx.kms_keys,
      var.enable_features.upgrade_notifications.kms_key_name,
      var.enable_features.upgrade_notifications.kms_key_name
    )
  )
}

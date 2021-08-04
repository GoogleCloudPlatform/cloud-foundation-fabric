/**
 * Copyright 2021 Google LLC
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
  # The Google provider is unable to validate certain configurations of
  # private_cluster_config when enable_private_nodes is false (provider docs)
  is_private = try(var.private_cluster_config.enable_private_nodes, false)
  peering = try(
    google_container_cluster.cluster.private_cluster_config.0.peering_name,
    null
  )
  peering_project_id = (
    try(var.peering_config.project_id, null) == null
    ? var.project_id
    : var.peering_config.project_id
  )
}

resource "google_container_cluster" "cluster" {
  provider                    = google-beta
  project                     = var.project_id
  name                        = var.name
  description                 = var.description
  location                    = var.location
  node_locations              = length(var.node_locations) == 0 ? null : var.node_locations
  min_master_version          = var.min_master_version
  network                     = var.network
  subnetwork                  = var.subnetwork
  logging_service             = var.logging_service
  monitoring_service          = var.monitoring_service
  resource_labels             = var.labels
  default_max_pods_per_node   = var.enable_autopilot ? null : var.default_max_pods_per_node
  enable_binary_authorization = var.enable_binary_authorization
  enable_intranode_visibility = var.enable_intranode_visibility
  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_tpu                  = var.enable_tpu
  initial_node_count          = 1
  remove_default_node_pool    = var.enable_autopilot ? null : true
  datapath_provider           = var.enable_dataplane_v2 ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"
  enable_autopilot            = var.enable_autopilot == true ? true : null

  # node_config {}
  # NOTE: Default node_pool is deleted, so node_config (here) is extranneous.
  # Specify that node_config as an parameter to gke-nodepool module instead.

  # TODO(ludomagno): compute addons map in locals and use a single dynamic block
  addons_config {
    dns_cache_config {
      enabled = var.addons.dns_cache_config
    }
    http_load_balancing {
      disabled = !var.addons.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.addons.horizontal_pod_autoscaling
    }
    dynamic "network_policy_config" {
      for_each = !var.enable_autopilot ? [""] : []
      content {
        disabled = !var.addons.network_policy_config
      }
    }
    cloudrun_config {
      disabled = !var.addons.cloudrun_config
    }
    istio_config {
      disabled = !var.addons.istio_config.enabled
      auth     = var.addons.istio_config.tls ? "AUTH_MUTUAL_TLS" : "AUTH_NONE"
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.addons.gce_persistent_disk_csi_driver_config
    }
  }

  # TODO(ludomagno): support setting address ranges instead of range names
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#cluster_ipv4_cidr_block
  ip_allocation_policy {
    cluster_secondary_range_name  = var.secondary_range_pods
    services_secondary_range_name = var.secondary_range_services
  }

  # TODO(ludomagno): make optional, and support beta feature
  # https://www.terraform.io/docs/providers/google/r/container_cluster.html#daily_maintenance_window
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = (
      length(var.master_authorized_ranges) == 0
      ? []
      : [var.master_authorized_ranges]
    )
    iterator = ranges
    content {
      dynamic "cidr_blocks" {
        for_each = ranges.value
        iterator = range
        content {
          cidr_block   = range.value
          display_name = range.key
        }
      }
    }
  }

  #the network_policy block is enabled if network_policy_config and network_dataplane_v2 is set to false. Dataplane V2 has built-in network policies.
  dynamic "network_policy" {
    for_each = var.addons.network_policy_config ? [""] : []
    content {
      enabled  = var.enable_dataplane_v2 ? false : true
      provider = var.enable_dataplane_v2 ? "PROVIDER_UNSPECIFIED" : "CALICO"
    }
  }

  dynamic "private_cluster_config" {
    for_each = local.is_private ? [var.private_cluster_config] : []
    iterator = config
    content {
      enable_private_nodes    = config.value.enable_private_nodes
      enable_private_endpoint = config.value.enable_private_endpoint
      master_ipv4_cidr_block  = config.value.master_ipv4_cidr_block
      master_global_access_config {
        enabled = config.value.master_global_access
      }
    }
  }

  # beta features

  dynamic "authenticator_groups_config" {
    for_each = var.authenticator_security_group == null ? [] : [""]
    content {
      security_group = var.authenticator_security_group
    }
  }

  dynamic "cluster_autoscaling" {
    for_each = var.cluster_autoscaling.enabled ? [var.cluster_autoscaling] : []
    iterator = config
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = config.value.cpu_min
        maximum       = config.value.cpu_max
      }
      resource_limits {
        resource_type = "memory"
        minimum       = config.value.memory_min
        maximum       = config.value.memory_max
      }
      // TODO: support GPUs too
    }
  }

  dynamic "database_encryption" {
    for_each = var.database_encryption.enabled ? [var.database_encryption] : []
    iterator = config
    content {
      state    = config.value.state
      key_name = config.value.key_name
    }
  }

  dynamic "pod_security_policy_config" {
    for_each = var.pod_security_policy != null ? [""] : []
    content {
      enabled = var.pod_security_policy
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
      var.resource_usage_export_config.enabled != null
      &&
      var.resource_usage_export_config.dataset != null
      ? [""] : []
    )
    content {
      enable_network_egress_metering = var.resource_usage_export_config.enabled
      bigquery_destination {
        dataset_id = var.resource_usage_export_config.dataset
      }
    }
  }

  dynamic "vertical_pod_autoscaling" {
    for_each = var.vertical_pod_autoscaling == null ? [] : [""]
    content {
      enabled = var.vertical_pod_autoscaling
    }
  }

  dynamic "workload_identity_config" {
    for_each = var.workload_identity && !var.enable_autopilot ? [""] : []
    content {
      identity_namespace = "${var.project_id}.svc.id.goog"
    }
  }

}

resource "google_compute_network_peering_routes_config" "gke_master" {
  count                = local.is_private && var.peering_config != null ? 1 : 0
  project              = local.peering_project_id
  peering              = local.peering
  network              = element(reverse(split("/", var.network)), 0)
  import_custom_routes = var.peering_config.import_routes
  export_custom_routes = var.peering_config.export_routes
}

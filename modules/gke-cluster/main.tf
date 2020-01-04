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
  default_max_pods_per_node   = var.default_max_pods_per_node
  enable_binary_authorization = var.enable_binary_authorization
  enable_intranode_visibility = var.enable_intranode_visibility
  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_tpu                  = var.enable_tpu
  initial_node_count          = 1
  remove_default_node_pool    = true

  # node_config

  addons_config {
    http_load_balancing {
      disabled = ! var.addons.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = ! var.addons.horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = ! var.addons.network_policy_config
    }
    # beta addons
    # cloudrun is dynamic as it tends to trigger cluster recreation on change
    dynamic cloudrun_config {
      for_each = var.addons.istio_config.enabled && var.addons.cloudrun_config ? [""] : []
      content {
        disabled = false
      }
    }
    istio_config {
      disabled = ! var.addons.istio_config.enabled
      auth     = var.addons.istio_config.tls ? "AUTH_MUTUAL_TLS" : "AUTH_NONE"
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

  dynamic master_authorized_networks_config {
    for_each = length(var.master_authorized_ranges) == 0 ? [] : list(var.master_authorized_ranges)
    iterator = ranges
    content {
      dynamic cidr_blocks {
        for_each = ranges.value
        iterator = range
        content {
          cidr_block   = range.value
          display_name = range.key
        }
      }
    }
  }

  dynamic network_policy {
    for_each = var.addons.network_policy_config ? [""] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  dynamic private_cluster_config {
    for_each = var.private_cluster_config != null ? [var.private_cluster_config] : []
    iterator = config
    content {
      enable_private_nodes    = config.value.enable_private_nodes
      enable_private_endpoint = config.value.enable_private_endpoint
      master_ipv4_cidr_block  = config.value.master_ipv4_cidr_block
    }
  }

  # beta features

  dynamic authenticator_groups_config {
    for_each = var.authenticator_security_group == null ? [] : [""]
    content {
      security_group = var.authenticator_security_group
    }
  }

  dynamic cluster_autoscaling {
    for_each = var.cluster_autoscaling.enabled ? [var.cluster_autoscaling] : []
    iterator = config
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = config.cpu_min
        maximum       = config.cpu_max
      }
      resource_limits {
        resource_type = "memory"
        minimum       = config.memory_min
        maximum       = config.memory_max
      }
    }
  }

  dynamic database_encryption {
    for_each = var.database_encryption.enabled ? [var.database_encryption] : []
    iterator = config
    content {
      state    = config.value.state
      key_name = config.value.key_name
    }
  }

  dynamic pod_security_policy_config {
    for_each = var.pod_security_policy != null ? [""] : []
    content {
      enabled = var.pod_security_policy
    }
  }

  dynamic release_channel {
    for_each = var.release_channel != null ? [""] : []
    content {
      channel = var.release_channel
    }
  }

  dynamic resource_usage_export_config {
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

  dynamic vertical_pod_autoscaling {
    for_each = var.vertical_pod_autoscaling == null ? [] : [""]
    content {
      enabled = var.vertical_pod_autoscaling
    }
  }

  dynamic workload_identity_config {
    for_each = var.workload_identity ? [""] : []
    content {
      identity_namespace = "${var.project_id}.svc.id.goog"
    }
  }

}

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

locals {
  service_account_email = (
    var.node_service_account_create
    ? (
      length(google_service_account.service_account) > 0
      ? google_service_account.service_account[0].email
      : null
    )
    : var.node_service_account
  )
  service_account_scopes = (
    length(var.node_service_account_scopes) > 0
    ? var.node_service_account_scopes
    : (
      var.node_service_account_create
      ? ["https://www.googleapis.com/auth/cloud-platform"]
      : [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/monitoring.write"
      ]
    )
  )
  node_taint_effect = {
    "NoExecute"        = "NO_EXECUTE",
    "NoSchedule"       = "NO_SCHEDULE"
    "PreferNoSchedule" = "PREFER_NO_SCHEDULE"
  }
  temp_node_pools_taints = [
    for taint in var.node_taints :
    {
      "key"    = element(split("=", taint), 0),
      "value"  = element(split(":", element(split("=", taint), 1)), 0),
      "effect" = lookup(local.node_taint_effect, element(split(":", taint), 1)),
    }
  ]
  # The taint is added to match the one that
  # GKE implicitly adds when Windows node pools are created.
  win_node_pools_taint = (
    var.node_image_type == null
    ? []
    : length(regexall("WINDOWS", var.node_image_type)) > 0
    ? [
      {
        "key"    = "node.kubernetes.io/os"
        "value"  = "windows"
        "effect" = local.node_taint_effect.NoSchedule
      }
    ]
    : []
  )
  node_taints = concat(local.temp_node_pools_taints, local.win_node_pools_taint)
}

resource "google_service_account" "service_account" {
  count        = var.node_service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = "tf-gke-${var.name}"
  display_name = "Terraform GKE ${var.cluster_name} ${var.name}."
}

resource "google_container_node_pool" "nodepool" {
  provider = google-beta

  project  = var.project_id
  cluster  = var.cluster_name
  location = var.location
  name     = var.name

  initial_node_count = var.initial_node_count
  max_pods_per_node  = var.max_pods_per_node
  node_count         = var.autoscaling_config == null ? var.node_count : null
  node_locations     = var.node_locations
  version            = var.gke_version

  node_config {
    disk_size_gb      = var.node_disk_size
    disk_type         = var.node_disk_type
    image_type        = var.node_image_type
    labels            = var.node_labels
    taint             = local.node_taints
    local_ssd_count   = var.node_local_ssd_count
    machine_type      = var.node_machine_type
    metadata          = var.node_metadata
    min_cpu_platform  = var.node_min_cpu_platform
    oauth_scopes      = local.service_account_scopes
    preemptible       = var.node_preemptible
    service_account   = local.service_account_email
    tags              = var.node_tags
    boot_disk_kms_key = var.node_boot_disk_kms_key
    spot              = var.node_spot

    dynamic "guest_accelerator" {
      for_each = var.node_guest_accelerator
      iterator = config
      content {
        type  = config.key
        count = config.value
      }
    }

    dynamic "sandbox_config" {
      for_each = (
        var.node_sandbox_config != null
        ? [var.node_sandbox_config]
        : []
      )
      iterator = config
      content {
        sandbox_type = config.value
      }
    }

    dynamic "shielded_instance_config" {
      for_each = (
        var.node_shielded_instance_config != null
        ? [var.node_shielded_instance_config]
        : []
      )
      iterator = config
      content {
        enable_secure_boot          = config.value.enable_secure_boot
        enable_integrity_monitoring = config.value.enable_integrity_monitoring
      }
    }

    workload_metadata_config {
      mode = var.workload_metadata_config
    }

    dynamic "kubelet_config" {
      for_each = var.kubelet_config != null ? [var.kubelet_config] : []
      iterator = config
      content {
        cpu_manager_policy   = config.value.cpu_manager_policy
        cpu_cfs_quota        = config.value.cpu_cfs_quota
        cpu_cfs_quota_period = config.value.cpu_cfs_quota_period
      }
    }

    dynamic "linux_node_config" {
      for_each = var.linux_node_config_sysctls != null ? [var.linux_node_config_sysctls] : []
      iterator = config
      content {
        sysctls = config.value
      }
    }
  }

  dynamic "autoscaling" {
    for_each = var.autoscaling_config != null ? [var.autoscaling_config] : []
    iterator = config
    content {
      min_node_count = config.value.min_node_count
      max_node_count = config.value.max_node_count
    }
  }

  dynamic "management" {
    for_each = var.management_config != null ? [var.management_config] : []
    iterator = config
    content {
      auto_repair  = config.value.auto_repair
      auto_upgrade = config.value.auto_upgrade
    }
  }

  dynamic "upgrade_settings" {
    for_each = var.upgrade_config != null ? [var.upgrade_config] : []
    iterator = config
    content {
      max_surge       = config.value.max_surge
      max_unavailable = config.value.max_unavailable
    }
  }
}

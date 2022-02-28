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

resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
  for_each      = var.member_clusters
  membership_id = each.key
  project       = var.project_id
  endpoint {
    gke_cluster {
      resource_link = each.value
    }
  }
}

resource "google_gke_hub_feature" "configmanagement" {
  provider = google-beta
  for_each = var.features.configmanagement ? { 1 = 1 } : {}
  project  = var.project_id
  name     = "configmanagement"
  location = "global"
}

resource "google_gke_hub_feature" "mci" {
  provider = google-beta
  for_each = var.features.mc_ingress ? var.member_clusters : {}
  project  = var.project_id
  name     = "multiclusteringress"
  location = "global"
  spec {
    multiclusteringress {
      config_membership = google_gke_hub_membership.membership[each.key].id
    }
  }
}

resource "google_gke_hub_feature" "mcs" {
  provider = google-beta
  for_each = var.features.mc_servicediscovery ? { 1 = 1 } : {}
  project  = var.project_id
  name     = "multiclusterservicediscovery"
  location = "global"
}

resource "google_gke_hub_feature_membership" "feature_member" {
  provider   = google-beta
  for_each   = var.member_clusters
  project    = var.project_id
  location   = "global"
  feature    = google_gke_hub_feature.configmanagement["1"].name
  membership = google_gke_hub_membership.membership[each.key].membership_id

  dynamic "configmanagement" {
    for_each = (
      try(var.member_features.configmanagement, null) != null
      ? [var.member_features.configmanagement]
      : []
    )
    iterator = configmanagement

    content {
      version = try(configmanagement.value.version, null)

      dynamic "config_sync" {
        for_each = (
          try(configmanagement.value.config_sync, null) != null
          ? [configmanagement.value.config_sync]
          : []
        )
        iterator = config_sync
        content {
          git {
            https_proxy               = try(config_sync.value.https_proxy, null)
            sync_repo                 = try(config_sync.value.sync_repo, null)
            sync_branch               = try(config_sync.value.sync_branch, null)
            sync_rev                  = try(config_sync.value.sync_rev, null)
            secret_type               = try(config_sync.value.secret_type, null)
            gcp_service_account_email = try(config_sync.value.gcp_service_account_email, null)
            policy_dir                = try(config_sync.value.policy_dir, null)
          }
          source_format = try(config_sync.value.source_format, null)
        }
      }

      dynamic "policy_controller" {
        for_each = (
          try(configmanagement.value.policy_controller, null) != null
          ? [configmanagement.value.policy_controller]
          : []
        )
        iterator = policy_controller
        content {
          enabled                    = true
          exemptable_namespaces      = try(policy_controller.value.exemptable_namespaces, null)
          log_denies_enabled         = try(policy_controller.value.log_denies_enabled, null)
          referential_rules_enabled  = try(policy_controller.value.referential_rules_enabled, null)
          template_library_installed = try(policy_controller.value.template_library_installed, null)
        }
      }

      dynamic "binauthz" {
        for_each = (
          try(configmanagement.value.binauthz, false)
          ? [1]
          : []
        )
        content {
          enabled = true
        }
      }

      dynamic "hierarchy_controller" {
        for_each = (
          try(var.member_features.hierarchy_controller, null) != null
          ? [var.member_features.hierarchy_controller]
          : []
        )
        iterator = hierarchy_controller
        content {
          enabled                            = true
          enable_pod_tree_labels             = try(hierarchy_controller.value.enable_pod_tree_labels)
          enable_hierarchical_resource_quota = try(hierarchy_controller.value.enable_hierarchical_resource_quota)
        }
      }
    }
  }
}
